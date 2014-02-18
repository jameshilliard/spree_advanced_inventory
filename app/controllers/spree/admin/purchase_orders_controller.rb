module Spree
  module Admin
    class PurchaseOrdersController < ResourceController

      respond_to :html, only: [:index, :show, :destroy]
      respond_to :json, only: [:index, :show]
      respond_to :pdf, only: [:show, :submit]
      respond_to :rtf, only: [:show, :submit]

      before_filter :remove_unused, only: [:index]
      before_filter :find_or_create_office_address
      before_filter :load_supplier, only: [:create, :update]
      before_filter :find_or_build_address, only: [:create, :update]
      before_filter :update_orders, only: [:update]

      def index
        session[:return_to] = request.original_url

        params[:q] ||= {}

        # As date params are deleted if @show_only_completed, store
        # the original date so we can restore them into the params
        # after the search
        created_at_gt = params[:q][:created_at_gt]
        created_at_lt = params[:q][:created_at_lt]

        if !params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if params[:q][:status_cont] == "Submitted"
          params[:q][:submitted_at_lt] = params[:q][:created_at_lt]
          params[:q][:submitted_at_gt] = params[:q][:created_at_gt]
          params[:q].delete(:created_at_gt)
          params[:q].delete(:created_at_lt)

        elsif params[:q][:status_cont] == "Completed"
          params[:q][:completed_at_lt] = params[:q][:created_at_lt]
          params[:q][:completed_at_gt] = params[:q][:created_at_gt]
          params[:q].delete(:created_at_gt)
          params[:q].delete(:created_at_lt)
        end

        @search = Spree::PurchaseOrder.ransack(params[:q])
        @purchase_orders = @search.result(distinct: true).includes([:purchase_order_line_items, :user, :address, :variants]).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page])

        # Restore dates
        params[:q][:created_at_gt] = created_at_gt
        params[:q][:created_at_lt] = created_at_lt

        respond_with(@purchase_orders)
      end

      def show
        @purchase_order = find_resource

        respond_with(@purchase_order) do |format|
          format.html
          format.json { render(json: @purchase_order) }
          format.pdf { render(layout: false) }
          format.rtf { send_data(@purchase_order.save_rtf, type: "application/rtf; charset=utf-8; header=present", disposition: "attachment; filename=#{@purchase_order.number}.rtf") }

        end
      end

      def purchase_order

      end

      def new
        set_type
        redirect_to admin_purchase_order_edit_line_items_path(@purchase_order.number)
      end

      def update
        @purchase_order = Spree::PurchaseOrder.find_by_number(params[:id])

        if @purchase_order.update_attributes(params[:purchase_order])
          flash[:success] = "#{@purchase_order.po_type} updated"
          
          next_url = session[:return_to]||admin_purchase_orders_url()

          if params[:submit] =~ /edit/i
            next_url = edit_admin_purchase_order_path(@purchase_order.number)
          else
            session[:return_to] = nil
          end

          redirect_to next_url
        else
          render action: "edit"
        end
      end

      def edit_line_items
        @purchase_order = find_resource

        if @purchase_order.status.blank?
          @purchase_order.status = "New"
          @purchase_order.save validate: false
        end
        
        total_line_items = @purchase_order.purchase_order_line_items ? @purchase_order.purchase_order_line_items.size : 0

        @line_item_limit = 10 - total_line_items

        1.upto(@line_item_limit).each do |num|
          @purchase_order.purchase_order_line_items.build
        end

        if request.put? or request.post?
          params[:purchase_order][:purchase_order_line_items_attributes].each do |k,line_item|

            l = Spree::PurchaseOrderLineItem.where(purchase_order_id: @purchase_order.id,
                                                   variant_id: line_item["variant_id"]).first

            if l

              if line_item["quantity"].to_i > 0 and not line_item["quantity"].blank?

                l.update_attributes(quantity: line_item["quantity"],
                                    comment: line_item["comment"],
                                    price: line_item["price"])
              else
                l.destroy

              end

            else
              logger.info line_item.inspect

              if not line_item["variant_id"].blank? and
                not line_item["quantity"].blank? and 
                line_item["variant_id"].to_i > 0 and
                line_item["quantity"].to_i > 0 
                

                Spree::PurchaseOrderLineItem.create(variant_id: line_item["variant_id"],
                                                    purchase_order_id: @purchase_order.id,
                                                    quantity: line_item["quantity"].to_i,
                                                    comment: line_item["comment"],
                                                    price: line_item["price"].to_f,
                                                    user_id: spree_current_user.id)
              end
            end


          end

          redirect_to edit_admin_purchase_order_path(@purchase_order.number)

        end
      end

      def submit
        @purchase_order = find_resource

        ::ActiveRecord::Base.clear_all_connections!
        fork do
          sleep 10
          Spree::PurchaseOrderMailer.email_supplier(@purchase_order, false).deliver
          @purchase_order.status = "Submitted"
          @purchase_order.save validate: false
          exit
        end
        ::ActiveRecord::Base.establish_connection

        respond_with(@purchase_order) do |format|
          format.rtf { send_data(@purchase_order.save_rtf, type: "application/rtf; charset=utf-8; header=present", disposition: "attachment; filename=#{@purchase_order.number}.rtf") }
          format.pdf { render(action: "show", layout: false) }
        end

      end

      def complete
        @purchase_order = find_resource
        next_url = request.env["HTTP_REFERER"]

        if @purchase_order.dropship and @purchase_order.status == "Submitted"

          @purchase_order.status = "Completed"
          if @purchase_order.save
            if @purchase_order.orders 
              next_url = admin_order_payments_url(@purchase_order.orders.first)
            end
            flash[:success] = "#{@purchase_order.number} complete - You may capture payment on these orders now"
          else
            next_url = edit_admin_purchase_order_url(@purchase_order)
            flash[:error] = @purchase_order.errors.full_messages.join("; ")
          end
        else
          flash[:error] = "#{@purchase_order.number} is not a dropship or has not yet been submitted"
        end

        redirect_to next_url
      end

      def submitted
        @purchase_order = find_resource
        next_url = request.env["HTTP_REFERER"]

        if @purchase_order.status == "Entered"

          @purchase_order.status = "Submitted"
          if @purchase_order.save
            flash[:success] = "#{@purchase_order.number} marked as submitted"
          else
            next_url = edit_admin_purchase_order_url(@purchase_order)
            flash[:error] = @purchase_order.errors.full_messages.join("; ")
          end
        else
          flash[:error] = "#{@purchase_order.number} must have the status of Entered"
        end

        redirect_to next_url
      end      

      def destroy
        @purchase_order = Spree::PurchaseOrder.find_by_number(params[:id])
        next_url = admin_purchase_orders_url

        if @purchase_order
          flash[:success] = "#{@purchase_order.po_type} removed"

          @purchase_order.destroy
        else
          flash[:error] = "Could not load #{params[:id]}"
        end
        redirect_to next_url
      end

      protected

        def set_type
          @purchase_order = Spree::PurchaseOrder.new
          @purchase_order.dropship = (params[:type] == "DS" ? true : false)
          @purchase_order.user_id = spree_current_user.id
          @purchase_order.save validate: false
          @purchase_order.generate_number
          @purchase_order.purchase_order_line_items.build

          return @purchase_order
        end

        def find_resource
          param_id = params[:id] ? params[:id] : params[:purchase_order_id]
          po =  Spree::PurchaseOrder.find_by_number(param_id)
          @eligible_orders = Spree::Order.eligible_for_po(po)
          return po
        end

        def find_or_create_office_address
          @shipping_methods = ShippingMethod.where("display_on is null or display_on = '' or display_on = 'back_end'").order("zone_id asc, updated_at desc")

          country = Spree::Country.where('name = ? or iso = ? or iso3 = ? or iso_name = ?',
                                         Spree::Config.advanced_inventory_office_country,
                                         Spree::Config.advanced_inventory_office_country,
                                         Spree::Config.advanced_inventory_office_country,
                                         Spree::Config.advanced_inventory_office_country).first

          state = Spree::State.where('country_id = ? and (name = ? or abbr = ?)',
                                     country.id,
                                     Spree::Config.advanced_inventory_office_state.titleize,
                                     Spree::Config.advanced_inventory_office_state.upcase).first


          @office_address = Spree::Address.where(address1: Spree::Config.advanced_inventory_office_address1,
                                       address2: Spree::Config.advanced_inventory_office_address2,
                                       company: Spree::Config.advanced_inventory_office_company,
                                       city: Spree::Config.advanced_inventory_office_city,
                                       state_id: state.id,
                                       zipcode: Spree::Config.advanced_inventory_office_zip,
                                       country_id: country.id,
                                       phone: Spree::Config.advanced_inventory_office_phone,
                                       user_id: 1,
                                       firstname: "Shipping",
                                       lastname: "Receiving").first_or_create


        end

        def find_or_build_address
          if @purchase_order.dropship and params[:purchase_order][:address_id].to_i == 0
            @address = Spree::Address.where(firstname: params[:address][:firstname],
                                            lastname: params[:address][:lastname],
                                            company: params[:address][:company],
                                            phone: params[:address][:phone],
                                            alternative_phone: params[:address][:alternative_phone],
                                            address1: params[:address][:address1],
                                            address2: params[:address][:address2],
                                            city: params[:address][:city],
                                            zipcode: params[:address][:zipcode],
                                            country_id: params[:address][:country_id]).first





            if not @address
              @address = Spree::Address.new(params[:address])
              @address.save
            end

            params[:purchase_order][:address_id] = @address.id
          end
        end

        def remove_unused
          Spree::PurchaseOrder.where(status: nil, user_id: spree_current_user.id).each do |p|
            if p.purchase_order_line_items.size == 0
              p.destroy
            end
          end
        end

        def load_supplier
          supplier_contact = Spree::SupplierContact.find(params[:purchase_order][:supplier_contact_id])
          params[:purchase_order][:supplier_id] = supplier_contact.supplier_id
        end

        def update_orders
          eligible_orders = Spree::Order.eligible_for_po(@purchase_order)

          if params[:sending_manually] and params[:purchase_order][:status] == "Entered"
            params[:purchase_order][:status] = "Submitted"
          end

          if params[:order_ids] and params[:order_ids].size > 0
            @purchase_order.order_purchase_orders.destroy_all

            params[:order_ids].each do |oid|
              Spree::OrderPurchaseOrder.create(order_id: oid, purchase_order_id: @purchase_order.id)
            end

          elsif @purchase_order.status != "Completed" and not params[:order_ids] and eligible_orders.size > 0 
            @purchase_order.order_purchase_orders.destroy_all
          end
        end

    end
  end
end

module Spree
  module Admin
    class PurchaseOrdersController < ResourceController

      before_filter :remove_unused, only: [:index]
      before_filter :set_type, only: [:new]
      before_filter :find_or_create_office_address
      before_filter :find_or_build_address, only: [:create, :update]

      def submit

      end

      def sku_report

      end

      def supplier_report
      end

      def inventory_report
      end

      def open_dropship_report
      end

      protected

        def set_type
          @purchase_order = Spree::PurchaseOrder.new
          @purchase_order.dropship = (params[:type] == "DS" ? true : false)
          @purchase_order.user_id = spree_current_user.id
          @purchase_order.save
          @purchase_order.purchase_order_line_items.build

        end

        def find_resource
          @purchase_order ||= Spree::PurchaseOrder.find_by_number(params[:id])
        end

        def find_or_create_office_address
          @office_address = Spree::Address.where(address1: "219 N. Milwaukee St",
                                       address2: "Ste 3a",
                                       company: "800-CEO-READ",
                                       city: "Milwaukee",
                                       state_id: 4,
                                       zipcode: "53202",
                                       country_id: 49,
                                       phone: "800-236-7323",
                                       user_id: 1,
                                       firstname: "Shipping",
                                       lastname: "Receiving").first_or_create


        end

        def find_or_build_address
          if @purchase_order.dropship
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
          Spree::PurchaseOrder.destroy_all(status: nil,
                                           user_id: spree_current_user.id)
        end

    end
  end
end

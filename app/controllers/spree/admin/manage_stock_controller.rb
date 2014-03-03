module Spree
  module Admin
    class ManageStockController < BaseController
      require 'barby'
      require 'barby/barcode/bookland'
      require 'barby/outputter/html_outputter'

      def index

      end

      def full_inventory_report
        @inventory = Spree::FullInventory.where{
          ((count_on_hand + reserved_units) != 0) &
          ((state == nil) | (state == 'sold')) &
          ((is_dropship == nil) | (is_dropship == false)) &
          ((is_quote == nil) | (is_quote == false))
        }.
        order("title asc, sku asc")

        if params[:sku] and params[:sku].size > 0
          @inventory = @inventory.where(sku: params[:sku].strip)
        else
          if params[:first_letter]
            l = params[:first_letter].to_s
            @inventory = @inventory.where{(title =~ "#{l}%")}
          end

        end


        render layout: false
      end

      def receive_entire_po
        @po = Spree::PurchaseOrder.find_by_number(params[:purchase_order_id])
        r = {}
        @po.purchase_order_line_items.each do |p|
          if p.status != "Complete"
            r[p.id] = p.quantity
            p.receive(p.quantity)

            if p.variant.respond_to?(:admin_log_user_id)
              p.variant.update_column(:admin_log_user_id, spree_current_user.id)
            end
          end
        end

        @po.items_received(r)

        flash[:success] = "PO #{@po.number} fully received"
        redirect_to admin_purchase_orders_path
      end

      def update
        @variant = Spree::Variant.find(params[:variant_id])

        @po_line_items =
          @variant.purchase_order_line_items.
          joins(:purchase_order).
          where('spree_purchase_orders.dropship' => false).
          order("created_at desc").
          limit(50)


        @ds_line_items =
          @variant.purchase_order_line_items.
          joins(:purchase_order).
          where('spree_purchase_orders.dropship' => true).
          order("created_at desc").
          limit(20)

        if request.post?
          quantity = params[:receive].to_i
          if quantity > 0            
            if params[:receive_type] == "po"
              @line_item = Spree::PurchaseOrderLineItem.find(params[:received_id])

              if @line_item

                if @line_item.variant.respond_to?(:admin_log_user_id)
                  @line_item.variant.update_column(:admin_log_user_id, spree_current_user.id)
                end

                @line_item.receive(quantity)
                @line_item.purchase_order.items_received(@line_item.id => quantity)

                flash[:success] = flash_message_for(@variant, "received stock")
                redirect_to action: :update, variant_id: @variant.id

              else
                flash[:error] = flash_message_for(@variant, "Could not find that purchase order line item")
                redirect_to action: :update, variant_id: @variant.id, method: "get"
              end
            end
          end
        end
      end
    end
  end
end



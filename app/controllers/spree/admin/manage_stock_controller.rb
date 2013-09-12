module Spree
  module Admin
    class ManageStockController < BaseController

      def index

      end

      def full_inventory_report
        @inventory = Spree::Variant.where("spree_variants.count_on_hand > 0").select("spree_variants.*, spree_products.name as title").joins(:product).
                                    order("spree_products.name asc, spree_variants.sku asc")
        render layout: false
      end

      def receive_entire_po
        @po = Spree::PurchaseOrder.find_by_number(params[:purchase_order_id])

        @po.purchase_order_line_items.each do |p|
          if p.status != "Complete"
            p.receive(p.quantity - p.received)
          end
        end

        @po.items_received
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
          if params[:receive].to_i > 0
            if params[:receive_type] == "po"
              @line_item = Spree::PurchaseOrderLineItem.find(params[:received_id])

              if @line_item

                @line_item.receive(params[:receive])

                @line_item.purchase_order.items_received

                flash[:success] = flash_message_for(@variant, "received stock")
                redirect_to action: :update, variant_id: @variant.id

              else
                flash[:error] = flash_message_for(@variant, "Could not find that purchase order line item")
                redirect_to action: :update, variant_id: @variant.id, method: "get"
              end
            elsif params[:receive_type] == "independent"
              @variant.increment!(:count_on_hand, params[:receive].to_i)
              flash[:success] = "Received #{params[:receive]} units of #{@variant.product.name}"
              redirect_to action: :update, variant_id: @variant.id
            end

          else
            flash[:error] = flash_message_for(@variant, "Quantity received must be greater than 0")
            redirect_to action: :update, variant_id: @variant.id, method: "get"

          end


        end
      end

    end
  end
end



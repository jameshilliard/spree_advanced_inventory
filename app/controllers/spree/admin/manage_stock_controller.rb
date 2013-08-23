module Spree
  module Admin
    class ManageStockController < BaseController

      def index

      end

      def full_inventory_report
        @products = Spree::Products.join(:variants).
                                    where("spree_variants.on_hand" > 0).
                                    order("spree_products.name asc, spree_variants.sku asc")
        render layout: false
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

                flash[:success] = "Received #{params[:receive]} units of #{@variant.product.name}"
                redirect_to action: :index


              else
                flash[:error] = "Could not find that purchase order line item"
                redirect_to action: :update, variant_id: @variant.id, method: "get"
              end
            end

          else
            flash[:error] = "Quantity received must be greater than 0"
            redirect_to action: :update, variant_id: @variant.id, method: "get"

          end


        end
      end

    end
  end
end



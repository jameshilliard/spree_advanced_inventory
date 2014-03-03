module Spree
  module Admin
    class ManageStockController < BaseController

      def index

      end

      def full_inventory_report
        @inventory = Spree::Variant.select("spree_variants.*, spree_products.name as title, spree_products.permalink").joins(:product).
                                    order("spree_products.name asc, spree_variants.sku asc").where(is_master: false, deleted_at: nil)

        if sku_search = params[:sku]
          @inventory = @inventory.where{(sku =~ "%#{sku_search}%")}
        end

        if params[:first_letter]
          l = params[:first_letter].to_s
          @inventory = @inventory.where{(product.name =~ "#{l}%")}
        end

        if not params[:sku] or params[:sku].size == 0
          if params[:stock_level] == "backordered"
            @inventory = @inventory.where{(count_on_hand < 0)}
          elsif params[:stock_level] == "zero"
            @inventory = @inventory.where{(count_on_hand == 0)}
          elsif params[:stock_level] == "in_stock" or params[:stock_level].blank?
            @inventory = @inventory.where{((cost_price > 0.0) & (count_on_hand == 0)) | (count_on_hand > 0)}
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



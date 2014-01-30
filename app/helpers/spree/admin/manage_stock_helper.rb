module Spree
  module Admin
    module ManageStockHelper
      
      def url_for_queue(variant)
        if admin_product_inventory_path(variant.product) 
          admin_product_inventory_path(variant.product) + "##{variant.sku}"
        else
          admin_orders_path + "?q[variants_sku_cont]=#{variant.sku}&q[shipment_state_not_eq]=shipped"
        end
      end

      def recent_price_history(variant)
        rp = variant.last_purchase_order_line_item

        if rp and rp.purchase_order
          price_history = "" 

          variant.purchase_order_line_items.where{(price > 0.0)}.order("updated_at desc").limit(10).each do |l|
            price_history += l.updated_at.strftime("%m/%d/%Y") + " > #{l.purchase_order.number} > #{Spree::Money.new(l.price)}\n"
          end

          price_history
        else
          "Variant cost price only"
        end
      end

    end
  end
end

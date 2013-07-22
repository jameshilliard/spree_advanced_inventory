module Spree::Admin::PurchaseOrdersHelper
  def line_item_details(line_items)
    item_list = ""

    unless line_items.size == 0
      line_items.each do |l|
        sku = l.variant.sku
        if l.purchase_order.status == "Submitted"
          sku = link_to("<em>Receive #{sku}</em>?", admin_stock_update_path(variant_id: l.variant.id))
        end
        item_list += "(#{l.quantity} @ #{number_to_currency(l.price)}) &nbsp; #{l.variant.product.name.split(":").first} &mdash; #{sku}<br/>"
      end
    end

    return item_list.html_safe
  end

end

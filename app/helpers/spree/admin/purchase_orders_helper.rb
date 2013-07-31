module Spree::Admin::PurchaseOrdersHelper
  def line_item_details(line_items)
    item_list = ""

    unless line_items.size == 0
      line_items.each do |l|
        sku = l.variant.sku
        if l.purchase_order.status == "Submitted" and not l.purchase_order.dropship
          sku = link_to("<em>Receive #{sku}</em>?".html_safe, admin_stock_update_path(variant_id: l.variant.id))
        end
        item_list += "(#{l.quantity} @ #{number_to_currency(l.price)}) &nbsp; #{l.variant.product.name.split(":").first} &mdash; #{sku}<br/>".html_safe
      end
    end

    return item_list
  end

end

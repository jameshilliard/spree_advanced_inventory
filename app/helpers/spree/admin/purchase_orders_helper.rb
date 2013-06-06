module Spree::Admin::PurchaseOrdersHelper
  def line_item_details(line_items)
    item_list = ""

    unless line_items.size == 0
      line_items.each do |l|
        item_list += "(#{l.quantity} @ #{number_to_currency(l.price)}) &nbsp; #{l.variant.product.name.split(":").first} &mdash; #{l.variant.sku}<br/>"
      end
    end

    return item_list.html_safe
  end

end

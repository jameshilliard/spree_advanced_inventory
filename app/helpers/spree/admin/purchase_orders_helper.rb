module Spree::Admin::PurchaseOrdersHelper
  def line_item_details(line_items)
    item_list = ""

    po = line_items.first.purchase_order

    unless line_items.size == 0
      item_list = "<span class='small'>"
      line_items.each do |l|

        if l.variant and l.variant.try(:sku)
          sku = l.variant.sku
          if po.can_be_received? and l.status != "Complete"
            sku = link_to("<em>Receive #{sku}</em>?".html_safe, admin_stock_update_path(variant_id: l.variant.id))
          else
            if admin_product_inventory_path(l.variant.product)
              sku = link_to(sku, admin_product_inventory_path(l.variant.product) + "##{l.variant.sku}", target: "_BLANK")
            else
              sku = link_to(sku, edit_admin_product_variant_path(product_id: l.variant.product, id: l.variant), target: "_BLANK")
            end
          end
          item_list += "(#{l.quantity}) &nbsp; #{l.variant.product.name.split(":").first} &mdash; #{sku}<br/>".html_safe
        end
      end

      if po.can_be_fully_received? and 
        item_list += "#{link_to 'Receive Whole PO?', admin_receive_entire_po_path(po), confirm: "Ok to confirm this entire purchase order?"}".html_safe
      end
    end

    item_list += "</span><br/>".html_safe

    return item_list
  end

end


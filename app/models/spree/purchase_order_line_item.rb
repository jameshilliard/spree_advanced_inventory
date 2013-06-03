class Spree::PurchaseOrderLineItem < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :variant
  belongs_to :line_item

  attr_accessible :price, :quantity, :quantity_received, :received_at,
    :purchase_order_id, :variant_id, :line_item_id

  def searcher
    purchase_order.dropship ? Spree::LineItem : Spree::Variant
  end

  def product
    purchase_order.dropship ? line_item.product : variant.product
  end
end

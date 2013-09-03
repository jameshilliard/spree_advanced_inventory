class Spree::PurchaseOrderLineItem < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :variant
  belongs_to :line_item
  belongs_to :user

  has_many :received_purchase_order_line_items

  attr_accessible :price, :quantity, :purchase_order_id, :variant_id,
    :user_id

  validates :variant_id, presence: true
  validates :quantity, :price, numericality: true

  def product
    variant.product
  end

  def status
    (received_purchase_order_line_items.sum(:quantity) == quantity) ? "Complete" : "Incomplete"
  end

  def receive(qty_recv)
    received_purchase_order_line_items.create(quantity: qty_recv, received_at: Time.now)
    receive_total = qty_recv

    if variant.on_hand > 0
      receive_total = variant.on_hand + qty_recv
    end

    variant.update_attributes({ on_hand: receive_total})
  end

  def line_total
    quantity * price
  end

end

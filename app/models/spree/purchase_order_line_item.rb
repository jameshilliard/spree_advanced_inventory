class Spree::PurchaseOrderLineItem < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :variant
  belongs_to :line_item
  belongs_to :user

  has_many :received_purchase_order_line_items

  attr_accessible :price, :quantity, :purchase_order_id, :variant_id,
    :user_id, :comment

  validates :variant_id, presence: true
  validates :quantity, :price, numericality: true

  def product
    variant.product
  end

  def status
    (received_purchase_order_line_items.sum(:quantity).to_i == quantity.to_i) ? "Complete" : "Incomplete"
  end

  def receive(qty_recv)
    qty_recv = qty_recv.to_i
    received_purchase_order_line_items.create(quantity: qty_recv, received_at: Time.now)

    if variant.count_on_hand > 0
      variant.increment!(:count_on_hand, qty_recv)
    else
      variant.count_on_hand = qty_recv
    end
    variant.save
  end

  def received
    received_purchase_order_line_items.collect(&:quantity).sum
  end

  def line_total
    quantity * price
  end

end

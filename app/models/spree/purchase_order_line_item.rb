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
    received_purchase_order_line_items.create(quantity: qty_recv.to_i, received_at: Time.now)
  end

  def received
    received_purchase_order_line_items.pluck(:quantity).sum||0
  end

  def line_total
    quantity * price
  end

  def gross_profit_percentage
    total_revenue = 0.0

    if purchase_order.orders.size > 0
      purchase_order.orders.each do |o|
        total_revenue += o.line_items.where(variant_id: variant_id).sum("quantity * price").to_f
      end

      sprintf("%0.2f%", ((total_revenue - line_total) / total_revenue) * 100)
    else
      ""
    end
  end

end

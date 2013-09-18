class Spree::ReceivedPurchaseOrderLineItem < ActiveRecord::Base
  belongs_to :purchase_order_line_item
  belongs_to :purchase_order, through: :purchase_order_line_item
  attr_accessible :quantity, :received_at

end

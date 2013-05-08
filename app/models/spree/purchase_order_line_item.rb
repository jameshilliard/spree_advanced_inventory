class Spree::PurchaseOrderLineItem < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :variant
  attr_accessible :price, :quantity, :quantity_received, :received_at
end

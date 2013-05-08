class Spree::PurchaseOrder < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :address
  attr_accessible :dropship, :due_at, :status
end

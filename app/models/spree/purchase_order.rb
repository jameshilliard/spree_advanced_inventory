class Spree::PurchaseOrder < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :address
  belongs_to :shipping_method
  has_many :purchase_order_line_items

  attr_accessible :dropship, :due_at, :status, :address_id, :supplier_id,
    :user_id, :comments, :purchase_order_line_items_attributes, :discount,
    :shipping, :deposit, :shipping_method_id

  accepts_nested_attributes_for :purchase_order_line_items, reject_if: :all_blank

  before_validation :generate_number, :on => :create

  def generate_number
    record = true
    prefix = "PO"

    if dropship == true
      prefix = "DS"
    end

    while record
      random = "#{prefix}#{Array.new(9){rand(9)}.join}"
      record = self.class.where(:number => random).first
    end
    self.number = random if self.number.blank?
    self.number
  end

  def details
    item_list = ""

    unless purchase_order_line_items.size == 0
      purchase_order_line_items.each do |l|
        item_list += "(#{l.quantity}) #{l.product.name.split(":").first} - #{l.variant.sku}\n"
      end
    end

    return item_list
  end

  def to_param
    number.to_s.to_url.upcase
  end

end

class Spree::PurchaseOrder < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :address
  belongs_to :shipping_method
  belongs_to :user
  has_many :purchase_order_line_items, dependent: :destroy

  attr_accessible :dropship, :due_at, :status, :address_id, :supplier_id,
    :user_id, :comments, :purchase_order_line_items_attributes, :discount,
    :shipping, :deposit, :shipping_method_id

  accepts_nested_attributes_for :purchase_order_line_items,
   :reject_if => proc { |attributes| attributes['variant_id'].blank? }

  before_validation :generate_number, :on => :create

  validates :address_id, :supplier_id, :shipping_method_id, presence: true

  default_scope order("created_at desc")

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
        item_list += "(#{l.quantity}) #{l.variant.product.name.split(":").first} - #{l.variant.sku}\n"
      end
    end

    return item_list
  end

  def to_param
    number.to_s.to_url.upcase
  end

  def has_line_items?
    if purchase_order_line_items.size > 1
      true
    else
      purchase_order_line_items.first.new_record? ? false : true
    end
  end

end

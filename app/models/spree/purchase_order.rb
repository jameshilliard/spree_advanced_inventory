class Spree::PurchaseOrder < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :supplier_contact
  belongs_to :address
  belongs_to :shipping_method
  belongs_to :order
  belongs_to :user
  has_many :purchase_order_line_items, dependent: :destroy

  attr_accessible :dropship, :due_at, :status, :address_id, :supplier_id,
    :supplier_contact_id, :user_id, :comments, :terms, :order_id,
    :purchase_order_line_items_attributes, :discount, :shipping, :deposit,
    :shipping_method_id

  accepts_nested_attributes_for :purchase_order_line_items,
   :reject_if => proc { |attributes| attributes['variant_id'].blank? or attributes['variant_id'].to_i == 0 }

  before_validation :generate_number, :on => :create
  before_validation :copy_supplier_id

  validates :address_id, :shipping_method_id, presence: true

  default_scope order("spree_purchase_orders.created_at desc")

  scope :complete, lambda { where{(status == "Completed")} }
  scope :incomplete, lambda { where{(status != "Completed")} }

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

  def hardcopy_extension
    if supplier.try(:rtf_template)
      "rtf"
    else
      "pdf"
    end
  end

  def to_param
    number.to_s.to_url.upcase
  end

  def has_line_items?
    if purchase_order_line_items.size > 1
      true
    else
      (not purchase_order_line_items.first or purchase_order_line_items.first.new_record?) ? false : true
    end
  end

  def gross_amount
    sum = 0.0

    purchase_order_line_items.each do |l|
      sum += l.line_total
    end

    return sum
  end

  def total
    gross_amount.to_f + shipping.to_f - discount.to_f - deposit.to_f
  end

  def items_received
    completed_line_items = 0

    purchase_order_line_items.each do |l|
      unless l.status == "Incomplete"
        completed_line_items += 1
      end
    end

    if completed_line_items == purchase_order_line_items.size
      self.status = "Completed"
      self.save
    end
  end

  def self.update_status
	  where('status != ?', 'Completed').each do |po|
      po.items_received
    end
  end

  def can_destroy?
    if order and order.shipment_state == "shipped"
      false
    else
      true
    end
  end

  def po_type
    dropship ? "Dropship" : "Purchase Order"
  end

  def save_rtf
    if supplier and supplier.rtf_template and supplier.rtf_template.size > 0
      line_item = purchase_order_line_items.first

      t = supplier.rtf_template
      t.gsub!(/\|\|PONUM\|\|/, "#{number}")
      t.gsub!(/\|\|DATE\|\|/, "#{created_at.strftime("%m-%d-%Y")}")
      t.gsub!(/\|\|SPECIAL\|\|/, "#{shipping_method.name}")
      t.gsub!(/\|\|TU\|\|/, "#{line_item.quantity}")
      t.gsub!(/\|\|BUYER\|\|/, "#{user.email.split(/\@/).first}")
      t.gsub!(/\|\|SHIP1\|\|/, "#{address.company}")
      t.gsub!(/\|\|SHIP2\|\|/, "#{address.firstname} #{address.lastname}")
      t.gsub!(/\|\|SHIP3\|\|/, "#{address.address1}")
      t.gsub!(/\|\|SHIP4\|\|/, "#{address.address2}")
      t.gsub!(/\|\|SHIP5\|\|/, "#{address.city}")
      t.gsub!(/\|\|SHIP6\|\|/, "#{address.state.abbr}")
      t.gsub!(/\|\|SHIP7\|\|/, "#{address.zipcode}")
      t.gsub!(/\|\|ARRIVE\|\|/, "#{due_at}")
      t.gsub!(/\|\|SKU\|\|/, "#{line_item.variant.sku}")
      t.gsub!(/\|\|QTY\|\|/, "#{line_item.quantity}")
      t.gsub!(/\|\|TITLE\|\|/, "#{line_item.variant.product.name}")

      r = File.new(File.join(Rails.root, "tmp", "#{number}.rtf"), "w")
      r.write(t)

      return File.open(File.join(Rails.root, "tmp", "#{number}.rtf"), "r").read
    else 
      nil
    end
  end

  def self.states
    %w{Entered Submitted Completed}
  end

  def copy_supplier_id
    if supplier_contact
      self.supplier_id = supplier_contact.supplier_id
    end
    return true
  end

end

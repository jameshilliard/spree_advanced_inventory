class Spree::PurchaseOrder < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :supplier_contact
  belongs_to :address
  belongs_to :shipping_method
  belongs_to :user
  has_many :purchase_order_line_items, dependent: :destroy
  has_many :variants, through: :purchase_order_line_items
  has_many :order_purchase_orders
  has_many :orders, :through => :order_purchase_orders

  attr_accessible :dropship, :due_at, :status, :address_id, :supplier_id,
    :supplier_contact_id, :user_id, :comments, :terms, :order_id,
    :purchase_order_line_items_attributes, :discount, :shipping, :deposit,
    :shipping_method_id, :address_attributes, :email_subject, :auto_capture_orders,
    :entered_at, :completed_at, :submitted_at, :tax

  accepts_nested_attributes_for :purchase_order_line_items,
   :reject_if => Proc.new { |attributes| attributes['variant_id'].blank? or attributes['variant_id'].to_i == 0 }


  before_validation :copy_supplier_id
  before_validation :update_times
  before_validation :check_email_subject
  before_validation :receive_dropship_line_items
  before_save :send_completed_notice

  validates :address_id, :shipping_method_id, :supplier_contact_id, presence: true
  validates :discount, numericality: true, unless: Proc.new { |a| a.discount.blank? }
  validates :shipping, numericality: true, unless: Proc.new { |a| a.shipping.blank? }
  validates :deposit, numericality: true, unless: Proc.new { |a| a.deposit.blank? }
  validates :tax, numericality: true, unless: Proc.new { |a| a.tax.blank? }

  default_scope order("spree_purchase_orders.created_at desc")

  scope :complete, lambda { where{(status == "Completed")} }
  scope :incomplete, lambda { where{(status != "Completed")} }

  def self.override_sort
    Spree::PurchaseOrder.with_exclusive_scope { yield }
  end

  def receive_dropship_line_items
    if dropship
      if status_changed? and status == "Completed" and status_was != "Completed"
        purchase_order_line_items.each do |l|

          diff = l.quantity - l.received_purchase_order_line_items.sum(:quantity).to_i

          if diff > 0
            Spree::ReceivedPurchaseOrderLineItem.create(purchase_order_line_item_id: l.id,
                                                        quantity: diff,
                                                        received_at: Time.current)
          end
        end
      end
    end
    return true
  end

  def valid_status
    if not status.blank? and status != "New"
      true
    else 
      false
    end
  end

  def copy_supplier_id
    if supplier_contact
      self.supplier_id = supplier_contact.supplier_id
    end
    return true
  end

  def update_times
    if status == "Entered" and not entered_at
      self.entered_at = Time.current
    elsif status == "Submitted" and not submitted_at
      self.submitted_at = Time.current
    elsif status == "Completed" and not completed_at
      self.completed_at = Time.current
    end

    if submitted_at and not entered_at
      self.entered_at = submitted_at
    end

    return true
  end

  def check_email_subject
    if email_subject.blank?
      self.email_subject = "[#{Spree::Config[:site_name]}] New #{po_type} ##{number}"
    end
    true
  end

  def received_purchase_order_line_items
    Spree::ReceivedPurchaseOrderLineItem.where("spree_purchase_order_line_items.purchase_order_id = ?", id).
      joins(:purchase_order_line_item)
  end

  def generate_number
    unless number and number.size > 0
      prefix = "P"

      if dropship == true
        prefix = "D"
      end

      self.number = "#{prefix}#{sprintf("%06d", id)}"
      self.save validate: false
    end
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

  def can_be_received?
    status == "Submitted" and not dropship
  end

  def can_be_fully_received?
    can_be_received? and received_purchase_order_line_items.size == 0
  end

  def set_completed_at
    if status == "Completed"
      last_item = received_purchase_order_line_items.order("received_at desc").limit(1).first
      if last_item and last_item.received_at
        self.completed_at = last_item.received_at
        self.save validate: false
      end
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
    gross_amount.to_f + shipping.to_f + tax.to_f - discount.to_f - deposit.to_f
  end

  def items_received(line_item_ids)
    line_item_ids.each do |line_item_id,qty_recv|
      l = Spree::PurchaseOrderLineItem.find(line_item_id)
      q = qty_recv

      orders.order("completed_at asc").each do |o|
        if q > 0
          q = fill_order_backorders(o, l.variant, q)

          if o.inventory_units.with_state('backordered').size == 0 and auto_capture_orders
            o.try_to_capture_payment
            o.try_to_update_shipment_state
          end
            
          o.update!
          o.save
        end
      end

      stock_remaining_units(l.variant, q)
    end

    if received_purchase_order_line_items.sum(:quantity) == purchase_order_line_items.sum(:quantity)
      self.status = "Completed"
      self.completed_at = Time.new
      self.save
    end
  end

  def fill_order_backorders(o, v, qty_recv)
    qty_adjust = 0

    o.inventory_units.where(variant_id: v.id, state: "backordered").each do |i|
      if qty_recv > 0
        i.state = "sold"
        i.save 
        qty_recv -= 1
        qty_adjust += 1
      end
    end

    # This changes on hand to reflect the above inventory units being sold
    if qty_adjust > 0 and v.count_on_hand < 0
      if v.respond_to?(:reason)
        v.reason = "Received #{qty_adjust} units from PO #{number} for order #{o.number}"
      end

      v.count_on_hand = v.count_on_hand + qty_adjust
      v.save
    end

    return qty_recv
  end

  def stock_remaining_units(variant, qty)
    # Any remaining quantity should be received normally
    if qty > 0 
      if variant.respond_to?(:reason)
        variant.reason = "Received #{qty} units from PO #{number}"
      end

      variant.receive(qty)
    end
  end

  def self.update_status
	  where('status = ?', 'Submitted').each do |po|
      if po.purchase_order_line_items.sum(:quantity) == po.received_purchase_order_line_items.sum(:quantity)
        po.status = "Completed"
        po.completed_at = Time.new
        po.save validate: false
      end
    end
  end

  def can_destroy?
    destroy_ok = true

    if status == "Entered"
      if orders 
        orders.collect(&:shipment_state).each do |s|
          if destroy_ok and s == "shipped"
            destroy_ok = false
          end
        end
      end
    else
      destroy_ok = false
    end

    destroy_ok
  end

  def po_type
    dropship ? "Dropship" : "Purchase Order"
  end

  def save_rtf
    if supplier and supplier.rtf_template and supplier.rtf_template.size > 0
      line_item = purchase_order_line_items.first

      if File.exists?(File.join(Rails.root, "tmp", "#{number}.rtf"))
        File.unlink(File.join(Rails.root, "tmp", "#{number}.rtf"))
      end

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
      t.gsub!(/\|\|SHIP8\|\|/, "#{address.phone}")
      t.gsub!(/\|\|ARRIVE\|\|/, "#{due_at}")
      t.gsub!(/\|\|SKU\|\|/, "#{line_item.variant.sku}")
      t.gsub!(/\|\|QTY\|\|/, "#{line_item.quantity}")
      t.gsub!(/\|\|TITLE\|\|/, "#{line_item.variant.product.name}")
      t.gsub!(/\|\|REF\|\|/, "#{orders.collect(&:number).join(', ')}")

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

  def self.convert_order_association
    where("order_id is not null").each do |po|
      o = Spree::Order.find(po.order_id)
      o.purchase_order_id = po.id
      o.save validate: false
    end
  end

  def send_completed_notice
    if not dropship and status_changed? and status == "Completed" and status_was != "Completed"
      begin
        if Spree::PurchaseOrderMailer.respond_to?(:delay)
          Spree::PurchaseOrderMailer.delay.completed_notice(self)
        else
          Spree::PurchaseOrderMailer.completed_notice(self).deliver
        end
      rescue Exception => e
        Rails.logger.error "*** Could not e-mail completion notice for #{number}"
        Rails.logger.error "*** #{e.message}"
      end
    end
  end
end

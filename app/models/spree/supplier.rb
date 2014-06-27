class Spree::Supplier < ActiveRecord::Base
  attr_accessible :account_number, :nr_account_number, :address1, :address2,
    :address3, :city, :country, :email, :fax, :name, :phone, :state, :url,
    :zip, :abbreviation, :intl_phone, :intl_fax, :supplier_contacts_attributes,
    :rtf_template, :comments, :po_comments, :discount_quantities, :discount_rates,
    :returnable_quantities, :returnable_rates

  has_many :supplier_contacts, dependent: :destroy, inverse_of: :supplier
  has_many :purchase_orders
  has_many :purchase_order_line_items, through: :purchase_orders
  has_many :variants, through: :purchase_order_line_items, uniq: true
  has_many :line_items, through: :variants
  has_many :orders, through: :line_items

  accepts_nested_attributes_for :supplier_contacts,
    allow_destroy: true,
    reject_if: proc { |attributes| attributes['name'].blank? }

  validates :account_number, :email, :name, :abbreviation, :phone, presence: true
  validate :must_have_one_contact
  validates_associated :supplier_contacts

  def to_s
    abbreviation ? abbreviation : name
  end

  def source_of_variant?(variant)
    Spree::PurchaseOrder.joins(:purchase_order_line_items).
      where("spree_purchase_orders.supplier_id = ? and spree_purchase_order_line_items.variant_id = ?", 
            id, variant.id).size > 0 ?
            true : false
  end

  def discounts_available?
    discount_array.size > 0 ? true : false
  end

  def price_at_quantity(variant, qty, returnable = false)
    variant.price * (1 - (quantity_discount(qty.to_f, returnable) / 100.0).to_d)
  end
  
  def quantity_discount(quantity, returnable = false)
    d = discount_array(returnable)
    q = quantity_array(returnable)

    i = 0

    if quantity >= q[0]
      until i == (q.size - 1)

        if (i+1 < q.size) and quantity < q[i+1]
          break

        else
          i += 1

        end
      end

      return d[i].to_i
    else
      return 0

    end

  end

  def quantity_array(returnable = false)
    quantities = discount_quantities ? discount_quantities : []

    if returnable and returnable == "true" or returnable == true
      quantities = returnable_quantities ? returnable_quantities : []
    end

    qa = quantities.split(/\n/)

    index = 0

    qa.each do |q|
      qa[index] = q.to_i
      index += 1

    end

    return qa
  end

  def discount_array(returnable = false)
    rates = discount_rates ? discount_rates : []

    if returnable and returnable == "true" or returnable == true
      rates = returnable_rates ? returnable_rates : []
    end

    da = rates.split(/\n/)

    index = 0

    da.each do |d|
      da[index] = d.to_i
      index += 1

    end

    return da
  end
  
  def firstname
    name
  end

  def lastname
    ""
  end

  def zipcode
    zip
  end

  def must_have_one_contact
    if supplier_contacts.size == 0
      errors.add(:supplier_contacts, "need at least one entry:")
    else
      true
    end
  end
end

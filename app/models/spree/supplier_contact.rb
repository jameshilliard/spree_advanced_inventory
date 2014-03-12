class Spree::SupplierContact < ActiveRecord::Base
  belongs_to :supplier, inverse_of: :supplier_contacts

  attr_accessible :address1, :address2, :address3, :city, :country, :email, :fax, :job_title, :name, :phone, :state, :supplier, :url, :zip, :supplier_id

  validates :email, presence: { message: "for contact must be provided" }, unless: "name.blank?"
  validates :name, presence: { message: "for contact must be provided" }, unless: "email.blank?"

  scope :eligible_for_select, lambda {
    where{
      (supplier.name != "") &
      (supplier.email != "") &
      (name != "") &
      (email != "")
    }.
    joins(:supplier).
    order("spree_suppliers.name asc, spree_supplier_contacts.name asc") 
  }

  def name_with_supplier
    "#{supplier.name} - #{name}"
  end

  def will_save?
    attributes['name'].blank?
  end
end

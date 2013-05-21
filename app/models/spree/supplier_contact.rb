class Spree::SupplierContact < ActiveRecord::Base
  belongs_to :supplier, inverse_of: :supplier_contacts

  attr_accessible :address1, :address2, :address3, :city, :country, :email, :fax, :job_title, :name, :phone, :state, :supplier, :url, :zip

  validates :supplier, presence: true
end

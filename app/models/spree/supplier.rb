class Spree::Supplier < ActiveRecord::Base
  attr_accessible :account_number, :address1, :address2, :address3, :city, :country, :email, :fax, :name, :phone, :state, :url, :zip
  has_many :supplier_contacts

  validates :name, presence: true
	validates :phone, presence: true
  validates :email, presence: true
  validates :supplier, presence: true

end

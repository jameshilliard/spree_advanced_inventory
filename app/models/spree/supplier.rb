class Spree::Supplier < ActiveRecord::Base
  attr_accessible :account_number, :address1, :address2, :address3, :city, :country, :email, :fax, :name, :phone, :state, :url, :zip, :abbreviation, :intl_phone, :intl_fax

  has_many :supplier_contacts

  validates :name, presence: true
  validates :address1, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip, presence: true
  validates :country, presence: true
	validates :phone, presence: true

end

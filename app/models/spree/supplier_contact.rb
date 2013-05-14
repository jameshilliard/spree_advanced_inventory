class Spree::SupplierContact < ActiveRecord::Base
  belongs_to :supplier
  attr_accessible :address1, :address2, :address3, :city, :country, :email, :fax, :intl_fax, :job_title, :name, :phone, :intl_phone, :state, :supplier, :url, :zip

  validates :name, presence: true
	validates :phone, presence: true
  validates :email, presence: true
  validates :supplier, presence: true
end

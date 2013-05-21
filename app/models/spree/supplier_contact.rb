class Spree::SupplierContact < ActiveRecord::Base
  belongs_to :supplier

  attr_accessible :address1, :address2, :address3, :city, :country, :email, :fax, :job_title, :name, :phone, :state, :supplier, :url, :zip

  validates :name, presence: true
	validates :phone, presence: true
  validates :email, presence: true
end

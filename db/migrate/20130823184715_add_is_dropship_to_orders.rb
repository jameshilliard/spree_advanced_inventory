class AddIsDropshipToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :is_dropship, :boolean, default: false
  end
end

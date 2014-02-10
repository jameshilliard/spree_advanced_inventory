class AddTaxToSpreePurchaseOrders < ActiveRecord::Migration
  def change
    add_column :spree_purchase_orders, :tax, :float, default: 0.0
  end
end

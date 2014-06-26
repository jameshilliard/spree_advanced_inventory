class AddDiscountsToSuppliers < ActiveRecord::Migration
  def change
    add_column :spree_suppliers, :discount_quantities, :text
    add_column :spree_suppliers, :discount_rates, :text
  end
end

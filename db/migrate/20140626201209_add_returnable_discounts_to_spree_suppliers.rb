class AddReturnableDiscountsToSpreeSuppliers < ActiveRecord::Migration
  def change
    add_column :spree_suppliers, :returnable_rates, :string
    add_column :spree_suppliers, :returnable_quantities, :string

  end
end

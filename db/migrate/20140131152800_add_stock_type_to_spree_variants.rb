class AddStockTypeToSpreeVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :stock_type, default: "R"
  end
end

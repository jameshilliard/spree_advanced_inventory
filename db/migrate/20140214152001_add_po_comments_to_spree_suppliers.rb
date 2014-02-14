class AddPoCommentsToSpreeSuppliers < ActiveRecord::Migration
  def change
    add_column :spree_suppliers, :po_comments, :text
  end
end


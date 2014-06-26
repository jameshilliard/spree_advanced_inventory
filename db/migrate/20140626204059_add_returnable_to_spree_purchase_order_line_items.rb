class AddReturnableToSpreePurchaseOrderLineItems < ActiveRecord::Migration
  def change
    add_column :spree_purchase_order_line_items, :returnable, :boolean, default: false
  end
end

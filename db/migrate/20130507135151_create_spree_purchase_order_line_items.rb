class CreateSpreePurchaseOrderLineItems < ActiveRecord::Migration
  def change
    create_table :spree_purchase_order_line_items do |t|
      t.references :purchase_order
      t.references :variant
      t.datetime :received_at
      t.integer :quantity
      t.decimal :price
      t.integer :quantity_received

      t.timestamps
    end
    add_index :spree_purchase_order_line_items, :purchase_order_id
    add_index :spree_purchase_order_line_items, :variant_id
  end
end

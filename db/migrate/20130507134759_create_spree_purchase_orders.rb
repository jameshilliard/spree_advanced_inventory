class CreateSpreePurchaseOrders < ActiveRecord::Migration
  def change
    create_table :spree_purchase_orders do |t|
      t.references :supplier
      t.references :address
      t.string :status
      t.boolean :dropship
      t.datetime :due_at
      t.text :comments

      t.timestamps
    end
    add_index :spree_purchase_orders, :supplier_id
    add_index :spree_purchase_orders, :address_id
  end
end

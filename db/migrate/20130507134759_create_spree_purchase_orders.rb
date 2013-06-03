class CreateSpreePurchaseOrders < ActiveRecord::Migration
  def change
    create_table :spree_purchase_orders do |t|
      t.string :number
      t.references :supplier
      t.references :line_item
      t.references :variant
      t.references :user
      t.references :address
      t.references :shipping_method
      t.string :status
      t.boolean :dropship
      t.datetime :due_at
      t.decimal :discount
      t.decimal :shipping
      t.decimal :deposit
      t.text :comments

      t.timestamps
    end

    add_index :spree_purchase_orders, :number
    add_index :spree_purchase_orders, :supplier_id
    add_index :spree_purchase_orders, :address_id
  end
end

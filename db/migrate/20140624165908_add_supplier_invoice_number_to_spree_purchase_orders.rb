class AddSupplierInvoiceNumberToSpreePurchaseOrders < ActiveRecord::Migration
  def change
    add_column :spree_purchase_orders, :supplier_invoice_number, :string, default: nil
  end
end

class AddLastScannedAtToSpreeVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :last_scanned_at, :datetime, default: nil
    add_index :spree_variants, :last_scanned_at
  end
end

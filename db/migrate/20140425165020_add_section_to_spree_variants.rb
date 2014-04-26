class AddSectionToSpreeVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :section, :integer, default: nil
    add_index :spree_variants, :section
  end
end

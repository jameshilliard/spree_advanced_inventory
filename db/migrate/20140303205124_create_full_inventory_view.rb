class CreateFullInventoryView < ActiveRecord::Migration
  def up
    execute("
create view full_inventory as 

select v1.id, v1.sku, v1.cost_price, v1.count_on_hand, reserved_units, v1.name as title, v1.permalink 
from (select spree_variants.id, spree_variants.sku, spree_variants.cost_price, spree_variants.count_on_hand, spree_products.name, spree_products.permalink from spree_variants, spree_products where spree_variants.is_master = false and spree_products.id = spree_variants.product_id) v1
left join (select variant_id, count(id) as reserved_units from spree_inventory_units where state = 'sold' and is_dropship = false and is_quote = false group by variant_id) i
on v1.id = i.variant_id

")            
  end

  def down
    execute("drop view full_inventory")
  end
end

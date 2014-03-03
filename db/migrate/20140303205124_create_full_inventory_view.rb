class CreateFullInventoryView < ActiveRecord::Migration
  def up
    execute("
create view full_inventory as 

select 
v.id, v.sku, v.cost_price, v.count_on_hand, 
count(i.id) as reserved_units, i.state, i.is_dropship, i.is_quote,
p.name as title, p.permalink

from spree_variants v

left join spree_inventory_units i on i.variant_id = v.id
join spree_products p on p.id = v.product_id

where 
v.is_master = false

group by 
v.id, i.state, i.is_dropship, i.is_quote, p.name, p.permalink

")            
  end

  def down
    execute("drop view full_inventory")
  end
end

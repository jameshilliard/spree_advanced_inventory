class CreateFullInventoryView < ActiveRecord::Migration
  def up
    execute("
create view full_inventory as 

select 
v.id, v.sku, v.cost_price, v.count_on_hand, count(i.id) as reserved_units, i.state

from spree_variants v

left join spree_inventory_units i 

on i.variant_id = v.id

where 
v.is_master = false 

group by 
v.id, i.state

")            
  end

  def down
    execute("drop view full_inventory")
  end
end

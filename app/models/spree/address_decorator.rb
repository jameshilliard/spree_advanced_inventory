Spree::Address.class_eval do
  def self.eligible_for_po(po)
    variant_ids = Array.new
    
    po.purchase_order_line_items.each do |l|
      variant_ids.push(l.variant_id)
    end
  
    find_by_sql("select a.* from spree_addresses a, spree_orders o, spree_line_items l where (a.id = o.ship_address_id or a.id = o.bill_address_id) and o.completed_at is not null and o.state = 'complete' and l.order_id = o.id and l.variant_id in (#{variant_ids.join(", ")}) order by a.lastname asc, a.firstname asc limit 100")  
  end
end

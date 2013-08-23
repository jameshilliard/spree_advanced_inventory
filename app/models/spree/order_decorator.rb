Spree::Order.class_eval do
  has_many :purchase_orders
  attr_accessible :is_dropship

  def to_select
    value = "#{number} - #{created_at.strftime("%m/%d/%Y %H:%M")} - From: #{email} - $#{total}"

    return value
  end

  def self.eligible_for_po(po)
    variant_ids = Array.new
    
    po.purchase_order_line_items.each do |l|
      variant_ids.push(l.variant_id)
    end

    dropship_check = ""

    if po.dropship
      dropship_check = "o.is_dropship = true and"
    end
  
    find_by_sql("select o.* from spree_orders o, spree_line_items l where o.completed_at is not null and #{dropship_check} o.state = 'complete' and l.order_id = o.id and l.variant_id in (#{variant_ids.join(", ")}) order by o.completed_at desc limit 100")
  end
end

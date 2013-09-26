Spree::Order.class_eval do
  belongs_to :purchase_order
  attr_accessible :is_dropship, :inventory_adjusted

  before_validation :dropship_conversion

  def to_select
    value = "#{number} - From: #{email} - $#{total}"

    return value
  end

  def dropship_conversion
    if updated_at
      if is_dropship and is_dropship_changed? and is_dropship_was == false and not inventory_adjusted and (Time.current - updated_at > 300)
        line_items.each do |l|
          l.variant.receive_quantity(l.quantity)
        end

        inventory_units.each do |i|
          i.state = 'sold'
          i.save
        end

        self.inventory_adjusted = true
        
      end
    end
    return true
  end

  def self.eligible_for_po(po)
    dropship_check = ""

    if po.dropship
      dropship_check = "o.is_dropship = true and"
    end
  
    find_by_sql(["select o.* 
                from spree_orders o, spree_line_items l 
                where o.completed_at is not null and #{dropship_check} 
                o.state = 'complete' and 
                l.order_id = o.id and 
                l.variant_id in (select distinct(variant_id) from spree_purchase_order_line_items where purchase_order_id = ?) 
                order by 
                o.completed_at desc limit 100", po.id])
  end
end

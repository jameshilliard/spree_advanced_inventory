Spree::Order.class_eval do
  has_many :purchase_orders

  attr_accessible :is_dropship, :inventory_adjusted

  before_validation :dropship_conversion

  def to_select
    value = "#{number} - From: #{email} - $#{total}"

    return value
  end

  def dropship_conversion 
    if is_dropship and is_dropship_changed? and not inventory_adjusted
      # The first time an order is changed from non_dropship
      # to a dropship, this adds the units back into inventory 
      line_items.each do |l|
        l.variant.increment!(:count_on_hand, l.quantity)
      end

      self.inventory_adjusted = true
      
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

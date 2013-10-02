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
      if is_dropship_changed? and 
        if is_dropship and is_dropship_was == false and not inventory_adjusted 

          line_items.each do |l|

            if ((Time.new - created_at) > 300)
              l.variant.receive(l.quantity)
              self.inventory_adjusted = true
            end

            inventory_units.where(variant_id: l.variant_id).each do |i|
              i.state = 'sold'
              i.is_dropship = true
              i.save validate: false

            end
          end


        elsif not is_dropship and is_dropship_was == true 
          line_items.each do |l|
            current_on_hand = l.variant.on_hand

            if inventory_adjusted
              l.variant.decrement!(:count_on_hand, l.quantity)
            end

            if current_on_hand >= l.quantity
              # These units should already be sold but make sure!
              inventory_units.where(variant_id: l.variant_id).each do |i|
                i.state = 'sold'
                i.is_dropship = false
                i.save validate: false

              end
            else
              counter = 1
              inventory_units.where(variant_id: l.variant_id).each do |i|

                if counter <= current_on_hand
                  i.state = 'sold'
                else
                  i.state = 'backordered'
                end

                i.is_dropship = false
                i.save validate: false
                counter += 1
              end
            end
            
            # This resets the check for inventory adjustments in case the admin keeps changing the
            # dropship state back and forth
            self.inventory_adjusted = false
          end
        end 
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
                o.shipment_state != 'shipped' and  
                l.order_id = o.id and 
                l.variant_id in (select distinct(variant_id) from spree_purchase_order_line_items where purchase_order_id = ?) 
                order by 
                o.completed_at desc limit 100", po.id])
  end
end

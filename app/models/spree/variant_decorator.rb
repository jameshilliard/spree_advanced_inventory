Spree::Variant.class_eval do
  has_many :purchase_order_line_items
  has_many :purchase_orders, through: :purchase_order_line_items
  has_many :orders, through: :line_items

  def receive(qty)
    if on_hand > 0
      qty += on_hand
    end

    self.on_hand = qty
    self.save
  end

  # This routine was always being called before saving variants and causing havok with 
  # stock levels
  def on_demand=(on_demand)
    #self[:on_demand] = on_demand
    #if on_demand
    #  inventory_units.with_state('backordered').each(&:fill_backorder)
    #end
  end

  def recent_price
    p = 0.0

    if rp = purchase_order_line_items.where{(price != nil) & (price >= 0.0)}.order("updated_at desc").limit(1).first
      p = rp.price
    elsif cost_price and cost_price > 0.0
      p = cost_price
    end

    return p
  end

  def increment!(attribute, by = 1)
    raise ArgumentError("Invalid attribute: #{attribute}") unless attribute_names.include?(attribute.to_s)
    original_value_sql = "CASE WHEN #{attribute} IS NULL THEN 0 ELSE #{attribute} END"
    self.class.update_all("#{attribute} = #{original_value_sql} + #{by.to_i}", "id = #{id}")
    reload
  end

  def decrement!(attribute, by = 1)
    raise ArgumentError("Invalid attribute: #{attribute}") unless attribute_names.include?(attribute.to_s)
    original_value_sql = "CASE WHEN #{attribute} IS NULL THEN 0 ELSE #{attribute} END"
    self.class.update_all("#{attribute} = #{original_value_sql} - #{by.to_i}", "id = #{id}")
    reload
  end

  private

    def process_backorders
      if count_changes = changes['count_on_hand']
        new_level = count_changes.last

        if Spree::Config[:track_inventory_levels] && !self.on_demand
          new_level = new_level.to_i
          order_list = Array.new

          # update backorders if level is positive
          if new_level > 0

            # fill backordered orders before creating new units
            backordered_units = inventory_units.with_state('backordered')
            backordered_units.slice(0, new_level).each do |i|
              unless order_list.include?(i.order_id)
                order_list.push(i.order_id)
              end
              i.fill_backorder
            end
            new_level -= backordered_units.length
          end

          if order_list.size > 0
            order_list.each do |oid|
              o = Spree::Order.find(oid)
              o.shipments.each do |shipment|

                unless shipment.state == "shipped"
                  shipment.update!(o)
                end
              end

              o.updater.update_shipment_state
              o.update_attributes_without_callbacks({ :shipment_state => o.shipment_state })
            end
          end
          self.update_attribute_without_callbacks(:count_on_hand, new_level)
        end
      end
    end    

end


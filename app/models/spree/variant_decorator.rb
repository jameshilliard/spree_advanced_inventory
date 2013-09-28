Spree::Variant.class_eval do
  has_many :purchase_order_line_items
  has_many :orders, through: :line_items

  def receive(qty)
    if on_hand > 0
      qty += on_hand
    end

    self.on_hand = qty
    self.save
  end

  def on_demand=(on_demand)
    #self[:on_demand] = on_demand
    #if on_demand
    #  inventory_units.with_state('backordered').each(&:fill_backorder)
    #end
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

            logger.info "\n\n*** Filling positive inventory level"
            # fill backordered orders before creating new units
            backordered_units = inventory_units.with_state('backordered')
            backordered_units.slice(0, new_level).each do |i|
              logger.info "*** Filling backorder on #{i.id}"
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
              o.update!
            end
          end
          self.update_attribute_without_callbacks(:count_on_hand, new_level)
        end
      end
    end    

    #def process_backorders
      #Rails.logger.info "\n\n*** PROCESS_BACKORDERS #{id}\n\n"

      #if count_changes = changes['count_on_hand']
        #new_level = count_changes.last

        #if Spree::Config[:track_inventory_levels] && !self.on_demand
          #new_level = new_level.to_i
          #updated_orders = []
          #bo_total = 0

          ## update backorders if level is positive
          #if new_level > 0
            #Rails.logger.info "*** #{new_level}"

            #inventory_units.with_state('backordered').each do |i|
              #Rails.logger.info "*** IU #{i.id}"

              #if new_level > 0
                #Rails.logger.info "\n\n*** #{i.id} is switching to SOLD from #{i.state}\n\n"
                #if i.update_column('state', 'sold')
                  #new_level -= 1

                  #unless updated_orders.include?(i.order_id)
                    #updated_orders.push(i.order_id)
                  #end
                #else
                  #bo_total += 1
                #end
              #else
                #bo_total += 1
              #end
            #end

            #if new_level > 0 and bo_total == 0
              #Rails.logger.info "*** On hand total = #{new_level}"
              #self.update_attribute_without_callbacks(:count_on_hand, new_level)
            #elsif bo_total > 0
              #Rails.logger.info "*** Back ordered total = #{bo_total}"
              #self.update_attribute_without_callbacks(:count_on_hand, (0 - bo_total))
            #end

            #updated_orders.each do |order_id|
              #o = Spree::Order.find(order_id)
              #i_count = o.inventory_units.where(variant_id: id, state: "backordered").size
              #Rails.logger.info "*** #{o.id} / #{o.number} has #{i_count} backordered units"

              #unless i_count > 0
                #o.shipments.reload.each { |shipment| shipment.update!(o) }
                #o.updater.update_shipment_state
                #o.save
              #end
            #end
          #else
            #self.update_attribute_without_callbacks(:count_on_hand, new_level)
          #end
        #end
      #end
    #end
end


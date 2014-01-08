Spree::InventoryUnit.class_eval do
  attr_accessible :is_dropship, :is_quote

  before_validation :set_stock_type

  def set_stock_type
    if order.is_dropship == true
      self.is_dropship = true

      if shipment.state != "shipped"
        self.state = "sold"
      elsif shipment.state == "shipped" and return_authorization_id == nil
        self.state = "shipped"
      end
    else
      self.is_dropship = false
    end 

    if order.is_quote == true
      self.is_quote = true
    else
      self.is_quote = false
    end 

    return true
  end

  def self.increase(order, variant, quantity)
    back_order = determine_backorder(order, variant, quantity)
    sold = quantity - back_order

    #set on_hand if configured
    if self.track_levels?(variant) and order.use_stock
      variant.decrement!(:count_on_hand, quantity)
    end

    #create units if configured
    if Spree::Config[:create_inventory_units]
      create_units(order, variant, sold, back_order)
    end
  end 

  def self.decrease(o, v, q)

    # Do not recreate stock levels for dropships
    if self.track_levels?(v) and o.use_stock
      v.increment!(:count_on_hand, q)
    end

    if Spree::Config[:create_inventory_units]
      destroy_units(o, v, q)
    end
  end
  
  private
    def update_order
      #order.update!
    end  

    def self.determine_backorder(o, v, q)

      if not o.use_stock
        0
      else
        if v.on_hand == 0 
          q
        elsif v.on_hand.present? and v.on_hand < q 
          q - (v.on_hand < 0 ? 0 : v.on_hand)
        else
          0
        end
      end
    end
end

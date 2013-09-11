Spree::InventoryUnit.class_eval do
  attr_accessible :is_dropship

  before_validation :set_is_dropship

  def set_is_dropship
    self.is_dropship = order.is_dropship||false
    return true
  end
  
  def self.decrease(o, v, q)

    # Do not recreate stock levels for dropships
    if self.track_levels?(v) and not o.is_dropship
      v.increment!(:count_on_hand, q)
    end

    if Spree::Config[:create_inventory_units]
      destroy_units(o, v, q)
    end
  end
  
  private
    def self.determine_backorder(o, v, q)

      if o.is_dropship
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

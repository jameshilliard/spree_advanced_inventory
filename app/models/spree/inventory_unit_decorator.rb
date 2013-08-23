Spree::InventoryUnit.class_eval do
  attr_accessible :is_dropship

  before_validation :set_is_dropship

  def set_is_dropship
    self.is_dropship = order.is_dropship
  end
  
  def self.decrease(order, variant, quantity)

    # Do not recreate stock levels for dropships
    if self.track_levels?(variant) and not order.is_dropship
      variant.increment!(:count_on_hand, quantity)
    end

    if Spree::Config[:create_inventory_units]
      destroy_units(order, variant, quantity)
    end
  end
  
  private
    def self.determine_backorder(order, variant, quantity)

      if order.is_dropship
        # Dropships immediately create stock for use with this order
        if self.track_levels?(variant)
          variant.increment!(:count_on_hand, quantity)
        end
        0
      else
        if variant.on_hand == 0 
          quantity
        elsif variant.on_hand.present? and variant.on_hand < quantity 
          quantity - (variant.on_hand < 0 ? 0 : variant.on_hand)
        else
          0
        end
      end
    end
end

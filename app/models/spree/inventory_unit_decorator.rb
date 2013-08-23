Spree::InventoryUnit.class_eval do
  private
    def self.determine_backorder(order, variant, quantity)
      if order.is_dropship?
        variant.on_hand += quantity
        variant.save
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

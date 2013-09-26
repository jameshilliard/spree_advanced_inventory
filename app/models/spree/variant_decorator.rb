Spree::Variant.class_eval do
  has_many :purchase_order_line_items

  def receive_quantity(num)
    num = num.to_i

    if on_hand < 0
      diff = num + on_hand
      
      self.on_hand = diff
      self.save

      if diff > 0
        self.on_hand = num - diff
        self.save

      end
    else
      increment!(:count_on_hand, num)
    end    
    self.save
  end

end


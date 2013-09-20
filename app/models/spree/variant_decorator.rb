Spree::Variant.class_eval do
  has_many :purchase_order_line_items

  def receive_quantity(num)
    if count_on_hand > 0
      self.on_hand += num
    else
      self.on_hand = num
    end

    self.save
  end
end


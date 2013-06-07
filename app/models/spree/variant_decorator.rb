Spree::Variant.class_eval do
  has_many :purchase_order_line_items
end


Spree::Order.class_eval do
  belongs_to :purchase_order
  attr_accessible :is_dropship, :inventory_adjusted, :is_quote

  before_validation :dropship_conversion
  before_validation :empty_nil_slug

  def to_select
    value = "#{number} - From: #{email} - $#{total}"

    return value
  end

  def use_stock
    if is_dropship or is_quote
      false
    else
      true
    end
  end

  def empty_nil_slug
    if slug == nil
      self.slug = ""
    end
    return true
  end

  def dropship_conversion
    if is_dropship 
      make_dropship

    elsif not is_dropship and is_dropship_was == true
      make_regular

    end 
    return true
  end

  def make_dropship
    line_items.each do |l|

      if inventory_adjusted == true
        adjust_variant_stock(l.variant, l.quantity)
        self.inventory_adjusted = false
      end

      variant_inventory_units(l.variant_id).each do |i|
        update_inventory_unit(i, "sold")
      end
    end
  end

  def make_regular
    line_items.each do |l|
      current_on_hand = l.variant.on_hand

      if not inventory_adjusted
        adjust_variant_stock(l.variant, l.quantity * -1)
        self.inventory_adjusted = true
      end

      if current_on_hand >= l.quantity
        variant_inventory_units(l.variant_id).each do |i|
          update_inventory_unit(i, "sold")
        end

      else
        counter = 1

        variant_inventory_units(l.variant_id).each do |i|
          if counter <= current_on_hand
            update_inventory_unit(i, "sold")
          else
            update_inventory_unit(i, "backordered")
          end

          counter += 1
        end
      end
    end
  end

  def variant_inventory_units(variant_id)
    inventory_units.where(variant_id: variant_id)
  end

  def adjust_variant_stock(variant, quantity)
    if quantity > 0
      variant.receive(quantity)
    else
      variant.decrement!(:count_on_hand, quantity.abs)
    end
  end

  def update_inventory_unit(i, new_state)
    i.state = new_state
    i.is_dropship = is_dropship
    i.save validate: false
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
                o.is_quote != true and
                l.variant_id in (select distinct(variant_id) from spree_purchase_order_line_items where purchase_order_id = ?) 
                order by 
                o.completed_at desc limit 100", po.id])
  end

  def after_cancel
    unless is_quote
      restock_items!

      Spree::OrderMailer.cancel_email(self.id).deliver
      unless %w(partial shipped).include?(shipment_state)
        self.payment_state = 'credit_owed'
      end
    end
  end  
end

Spree::Order.class_eval do
  has_many :purchase_orders

  def to_select
    value = "#{number} - #{created_at.strftime("%m/%d/%Y %H:%M")} - From: #{user.email} - $#{total}"

    return value
  end
end

Spree::Shipment.class_eval do
  def send_shipped_email
    unless order.is_quote
      Spree::ShipmentMailer.shipped_email(self.id).deliver
    end
  end  
end

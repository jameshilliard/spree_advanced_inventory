Spree::Shipment.class_eval do
  def send_shipped_email
    unless order.is_quote
      if Spree::ShipmentMailer.respond_to?(:delay)
        Spree::ShipmentMailer.delay.shipped_email(self.id)
      else
        Spree::ShipmentMailer.shipped_email(self.id).deliver
      end
    end
  end  
end

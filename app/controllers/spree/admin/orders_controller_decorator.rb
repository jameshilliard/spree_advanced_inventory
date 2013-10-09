Spree::Admin::OrdersController.class_eval do
  def new
    @order = Spree::Order.create
    if params[:is_quote]
      @order.update_column(:is_quote, true)
    end
    respond_with(@order)
  end  
end

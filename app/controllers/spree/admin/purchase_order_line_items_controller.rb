module Spree
  module Admin
    class PurchaseOrderLineItemsController < ResourceController
      respond_to :js

      def create
        @purchase_order_line_item =
          Spree::PurchaseOrderLineItem.create(
            user_id: spree_current_user.id,
            purchase_order_id: params[:purchase_order_id],
            variant_id: params[:add_variant_id],
            price: params[:add_price],
            quantity: params[:add_quantity])

        redirect_to edit_admin_purchase_order_path(@purchase_order_line_item.purchase_order.number)
      end
    end
  end
end

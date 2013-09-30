module Spree
  module Admin
    class ManageStockController < BaseController

      def index

      end

      def full_inventory_report

        @inventory = Spree::Variant.select("spree_variants.*, spree_products.name as title, spree_products.permalink").joins(:product).
                                    order("spree_products.name asc, spree_variants.sku asc").where(is_master: false, deleted_at: nil)

        if params[:first_letter]
          l = params[:first_letter].to_s
          @inventory = @inventory.where{(product.name =~ "#{l}%")}
        end

        if params[:stock_level] == "backordered"
          @inventory = @inventory.where{(count_on_hand < 0)}
        elsif params[:stock_level] == "zero"
          @inventory = @inventory.where{(count_on_hand == 0)}
        elsif params[:stock_level] == "in_stock" or params[:stock_level].blank?
          @inventory = @inventory.where{(count_on_hand > 0)}
        end

        render layout: false
      end

      def receive_entire_po
        @po = Spree::PurchaseOrder.find_by_number(params[:purchase_order_id])

        @po.purchase_order_line_items.each do |p|
          if p.status != "Complete"
            p.receive(p.quantity - p.received)
          end
        end

        @po.items_received
        @po.orders.each do |o|
          o.shipments.each do |shipment| 
            unless shipment.state == "shipped"
              shipment.update!(o)
            end
          end

          o.update_shipment_state
          o.update_attributes_without_callbacks({ :shipment_state => o.shipment_state })
        end
        flash[:success] = "PO #{@po.number} fully received"
        redirect_to admin_purchase_orders_path
      end

      def update
        @variant = Spree::Variant.find(params[:variant_id])

        @po_line_items =
          @variant.purchase_order_line_items.
          joins(:purchase_order).
          where('spree_purchase_orders.dropship' => false).
          order("created_at desc").
          limit(50)


        @ds_line_items =
          @variant.purchase_order_line_items.
          joins(:purchase_order).
          where('spree_purchase_orders.dropship' => true).
          order("created_at desc").
          limit(20)

        if request.post?
          quantity = params[:receive].to_i
          if quantity > 0            
            if params[:receive_type] == "po"
              @line_item = Spree::PurchaseOrderLineItem.find(params[:received_id])

              if @line_item

                @line_item.receive(quantity)

                @line_item.purchase_order.items_received
                @line_item.purchase_order.orders.each do |o|

                  unless o.inventory_units.where(variant_id: @variant_id, state: 'backordered').size > 0
                    o.shipments.each do |shipment| 
                      unless shipment.state == "shipped"
                        shipment.update!(o)
                      end
                    end

                    o.update_shipment_state
                    o.update_attributes_without_callbacks({ :shipment_state => o.shipment_state })
                  end
                end

                flash[:success] = flash_message_for(@variant, "received stock")
                redirect_to action: :update, variant_id: @variant.id

              else
                flash[:error] = flash_message_for(@variant, "Could not find that purchase order line item")
                redirect_to action: :update, variant_id: @variant.id, method: "get"
              end
            end
          else
            flash[:error] = flash_message_for(@variant, "Quantity received must be greater than 0")
            redirect_to action: :update, variant_id: @variant.id, method: "get"

          end


        end
      end

    end
  end
end



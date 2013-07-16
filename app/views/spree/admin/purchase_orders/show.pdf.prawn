require 'prawn/layout'

font "Helvetica"
im = "#{Rails.root.to_s}/public/assets/#{Spree::PrintInvoice::Config[:print_invoice_logo_path]}"

image im , at: [0,720] #, scale: 0.35

fill_color "E99323"

if @purchase_order.dropship
  text "Dropship", align: :right, style: :bold, size: 18
else
  text "Purchase Order", align: :right, style: :bold, size: 18
end

fill_color "000000"

move_down 2

font "Helvetica",  size: 10,  style: :bold
text "Purchase Order #: #{@purchase_order.number}", align: :right

font "Helvetica", size: 10

if @purchase_order.order_id 
  move_down 2
  text "Reference #: #{@purchase_order.order.number}", align: :right
end

render partial: "spree/admin/purchase_orders/prawn/company_info"

stroke_color "d8d8d8"

render partial: "spree/admin/purchase_orders/prawn/supplier", 
  locals: { address: @purchase_order.supplier }

render partial: "spree/admin/purchase_orders/prawn/account", 
  locals: { contact: @purchase_order.supplier_contact, supplier: @purchase_order.supplier }

render partial: "spree/admin/purchase_orders/prawn/ship_to", 
  locals: { address: @purchase_order.address }

move_down 10
font "Helvetica", size: 18
text "#{@purchase_order.created_at.strftime("%m/%d/%Y")}", align: :left


render partial: "spree/admin/purchase_orders/prawn/purchase_order_line_items"

move_down 8

pdf.render_file(File.join(Rails.root, "tmp", @purchase_order.number + ".pdf"))

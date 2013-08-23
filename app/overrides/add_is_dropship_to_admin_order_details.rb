Deface::Override.new(
  virtual_path: "spree/admin/orders/_form",
  insert_before: "[data-hook='admin_order_form_buttons']",
  name: "add_is_dropship_field_to_admin_order_details",
  partial: "spree/admin/orders/is_dropship_field")

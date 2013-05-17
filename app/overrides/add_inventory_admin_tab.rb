
Deface::Override.new(
  virtual_path: 'spree/layouts/admin',
  text: %q{ <%= tab(:inventory, icon: 'icon-barcode') %> },
  insert_bottom: "[data-hook='admin_tabs']",
  name: 'add_inventory_admin_tab')


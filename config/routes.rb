Spree::Core::Engine.routes.draw do
  namespace :spree do
    resources :purchase_order_line_items
  end


  namespace :spree do
    resources :purchase_orders
  end


  namespace :spree do
    resources :supplier_contacts
  end


  namespace :spree do
    resources :suppliers
  end


  # Add your extension routes here
end

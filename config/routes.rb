Spree::Core::Engine.routes.draw do
  namespace :spree do
    resources :supplier_contacts
  end


  namespace :spree do
    resources :suppliers
  end


  # Add your extension routes here
end

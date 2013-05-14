Spree::Core::Engine.routes.draw do

  namespace :spree do
    namespace :admin do
      resources :purchase_orders
    end
  end


  namespace :spree do
    namespace :admin do
      resources :supplier_contacts
    end
  end


  namespace :spree do
    namespace :admin do
      resources :suppliers
    end
  end


  # Add your extension routes here
end

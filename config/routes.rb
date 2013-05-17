Spree::Core::Engine.routes.draw do


  namespace :admin do
    resources :purchase_orders do
      collection do
        match 'receive'
        match 'inventory_update'

        get 'reports'
        get 'supplier_report'
        get 'inventory_report'
        get 'open_dropship_report'

      end
    end
  end


  namespace :admin do
    resources :supplier_contacts
  end

  namespace :admin do
    resources :suppliers
  end

  match 'admin/purchase_orders/reports' => 'spree/admin/purchase_orders#reports', as: 'admin_inventory'
  # Add your extension routes here
end

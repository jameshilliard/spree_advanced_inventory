Spree::Core::Engine.routes.draw do


  namespace :admin do
    get 'purchase_orders/reports' => 'purchase_orders#reports',
      as: 'purchase_order_reports'

    resources :purchase_orders do
      collection do
        match 'receive'
        match 'adjust'

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

  # Add your extension routes here
end

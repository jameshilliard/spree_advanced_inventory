Spree::Core::Engine.routes.draw do


  namespace :admin do
    resources :purchase_orders do
      collection do
        get 'inventory_report'
        get 'open_dropship_report'
      end

      match 'submit'
      match 'source'
      match 'item'

    end

    resources :purchase_order_line_items

    resources :supplier_contacts
    resources :suppliers do
      collection do
        get 'inventory_report'
      end
    end

    match 'adjust_inventory' => 'adjust_inventory#index', as: 'adjust_inventory'
    match 'receive_inventory' => 'receive_inventory#index', as: 'receive_inventory'
  end

end

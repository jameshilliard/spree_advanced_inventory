Spree::Core::Engine.routes.draw do


  namespace :admin do
    resources :purchase_orders do
      collection do
        get 'inventory_report'
        get 'open_dropship_report'

      end

      match 'edit_line_items'
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

    get 'manage_stock' => 'manage_stock#index', as: 'manage_stock'
    match 'manage_stock/:variant_id/update' => 'manage_stock#update',
      as: 'update_stock'

  end

end

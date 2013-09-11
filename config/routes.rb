Spree::Core::Engine.routes.draw do


  namespace :admin do
    resources :purchase_orders do
      collection do
        get 'inventory_report'
        get 'open_dropship_report'

      end

      match 'edit_line_items'
      match 'submit'
      match 'complete'
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
    get 'manage_stock/full_inventory_report' => 'manage_stock#full_inventory_report',
      as: 'full_inventory_report'

    match 'manage_stock/update' => 'manage_stock#update',
      as: 'stock_update'

    get "advanced_inventory_settings" => "advanced_inventory_settings#show",
      as: "advanced_inventory_settings"

    get "advanced_inventory_settings/edit" => "advanced_inventory_settings#edit",
      as: "edit_advanced_inventory_settings"

    put "advanced_inventory_settings" => "advanced_inventory_settings#update"
  end

end

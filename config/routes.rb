Rails.application.routes.draw do

  root 'sessions#redirect'

  controller :sessions do
    get    'login'  => :new
    post   'login'  => :create
    delete 'logout' => :destroy
  end

    match '/reports/day_detail', to: 'reports#day_detail', via: [:get, :post]
    match '/reports/day_summary', to: 'reports#day_summary', via: [:get, :post]
    match '/reports/goods_distribution_detail', to: 'reports#goods_distribution_detail', via: [:get, :post]
    match '/reports/goods_in_employees', to: 'reports#goods_in_employees', via: [:get, :post]
    match '/reports/depletion', to: 'reports#depletion', via: [:get, :post]
    match '/reports/weight_diff', to: 'reports#weight_diff', via: [:get, :post]
    match '/reports/production_by_employees', to: 'reports#production_by_employees', via: [:get, :post]
    match '/reports/production_by_type', to: 'reports#production_by_type', via: [:get, :post]
    match '/reports/production_summary', to: 'reports#production_summary', via: [:get, :post]
    match '/reports/current_user_balance', to: 'reports#current_user_balance', via: [:get, :post]

  resources :contractors

  resources :departments

  resources :records do
    get :recent, on: :collection
  end

  resources :users

  resources :employees

  resources :clients

  resources :products

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

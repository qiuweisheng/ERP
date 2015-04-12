Rails.application.routes.draw do
  root 'sessions#redirect'

  controller :sessions do
    get    'login'  => :new
    post   'login'  => :create
    delete 'logout' => :destroy
  end

  get '/reports/day_detail' => 'reports#day_detail'
  get '/reports/day_summary' => 'reports#day_summary'
  get '/reports/goods_distribution_detail' => 'reports#goods_distribution_detail'
  get '/reports/goods_in_employees' => 'reports#goods_in_employees'
  get '/reports/depletion' => 'reports#depletion'
  get '/reports/weight_diff' => 'reports#weight_diff'
  get '/reports/production_by_employees' => 'reports#production_by_employees'
  get '/reports/production_by_type' => 'reports#production_by_type'
  get '/reports/production_summary' => 'reports#production_summary'
  get '/reports/polish_detail_by_type' => 'reports#polish_detail_by_type'
  get '/reports/polish_detail_by_client' => 'reports#polish_detail_by_client'
  get '/reports/polish_summary' => 'reports#polish_summary'
  get '/reports/current_user_balance' => 'reports#current_user_balance'
  get '/reports/client_weight_difference' => 'reports#client_weight_difference'
  get '/reports/client_transactions' => 'reports#client_transactions'
  get '/reports/client_transactions_detail' => 'reports#client_transactions_detail'
  get '/reports/contractor_transactions' => 'reports#contractor_transactions'
  get '/reports/contractor_transactions_detail' => 'reports#contractor_transactions_detail'
  get '/reports/goods_flow' => 'reports#goods_flow'

  get '/records/print' => 'records#print'

  resources :contractors

  resources :departments

  resources :records

  resources :users

  resources :employees

  resources :clients

  resources :products

  resources :profiles, only: [:index, :edit, :update]

  # get 'profiles' => 'profiles#index'
  # get 'profiles/edit/:key' => 'profiles#edit'
  # post 'profiles/update' => 'profiles#update'

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

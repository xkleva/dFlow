Rails.application.routes.draw do

  namespace :api, :defaults => {:format => :json} do
    get 'check_connection' , to: 'api#check_connection'
    
    # Config API
    get 'config/role_list', to: 'config#role_list'

    # User API
    resources :users

    # Treenode API
    resources :treenodes

    
    get 'jobs', to: 'jobs#index'
    get 'jobs/job_metadata', to: 'jobs#job_metadata'
    get 'jobs/update_metadata', to: 'jobs#update_metadata'
    get 'jobs/process_request', to: 'jobs#process_request'
    get 'jobs/process_initiate', to: 'jobs#process_initiate'
    get 'jobs/process_done', to: 'jobs#process_done'
    get 'jobs/process_progress', to: 'jobs#process_progress'
    post 'jobs/create_job', to: 'jobs#create_job'

    get 'sources/fetch_source_data', to: 'sources#fetch_source_data'
    get 'sources/validate_new_objects', to: 'sources#validate_new_objects'

    get 'flows/get_flow', to: 'flows#get_flow'
    post 'flows/update_flow_steps', to: 'flows#update_flow_steps'
    
  end
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

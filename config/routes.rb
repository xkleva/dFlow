Rails.application.routes.draw do
  apipie
  resources :session

  # Assets routes
  get 'assets/work_order/:asset_id', to: 'assets#work_order'
  get 'assets/job_pdf/:asset_id', to: 'assets#job_pdf'
  get 'assets/job_file/:asset_id', to: 'assets#job_file'

  namespace :api, :defaults => {:format => :json} do
    get 'check_connection' , to: 'process#check_connection'

    # Config API
    get 'config/roles', to: 'config#role_list'
    get 'config/status_list', to: 'config#status_list'
    get 'config/states', to: 'config#state_list'
    get 'config/cas_url', to: 'config#cas_url'

    # User API
    resources :users

    # Treenode API
    resources :treenodes

    # Jobs API
    get 'jobs/unpublished_jobs', to: 'jobs#unpublished_jobs'
    get 'thumbnails/:id', to: 'jobs#thumbnail'
    resources :jobs
    get 'jobs/:id/restart', to: 'jobs#restart'
    get 'jobs/:id/quarantine', to: 'jobs#quarantine'
    get 'jobs/:id/unquarantine', to: 'jobs#unquarantine'
    get 'jobs/:id/new_flow_step', to: 'jobs#new_flow_step'

    # Sources API
    get 'sources/fetch_source_data', to: 'sources#fetch_source_data'
    get 'sources/validate_new_objects', to: 'sources#validate_new_objects'
    get 'sources', to: 'sources#index'
    get 'sources/:name', to: 'sources#fetch_source_data'

    #Process API
    get 'process/request_job/:code', to: 'process#request_job'
    get 'process/:job_id', to: 'process#update_process'

    # Publication log API
    resources :publication_log

    # Statuses API
    #get 'statuses/:id/new/:status', to: 'statuses#new'
    #get 'statuses/:id/complete/:status', to: 'statuses#complete'


    #get 'jobs', to: 'jobs#index'
    #get 'jobs/:id', to: 'jobs#show'
    #post 'jobs', to: 'jobs#create'

    #get 'jobs/job_metadata', to: 'jobs#job_metadata'
    #get 'jobs/update_metadata', to: 'jobs#update_metadata'
    #get 'jobs/process_request', to: 'jobs#process_request'
    #get 'jobs/process_initiate', to: 'jobs#process_initiate'
    #get 'jobs/process_done', to: 'jobs#process_done'
    #get 'jobs/process_progress', to: 'jobs#process_progress'

    

    #get 'flows/get_flow', to: 'flows#get_flow'
    #post 'flows/update_flow_steps', to: 'flows#update_flow_steps'

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

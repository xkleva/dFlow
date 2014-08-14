Rails.application.routes.draw do

  namespace :api, :defaults => {:format => :json} do
    get 'check_connection' , to: 'api#check_connection'
    
    get 'jobs/job_metadata', to: 'jobs#job_metadata'
    get 'jobs/update_metadata', to: 'jobs#update_metadata'
    get 'jobs/process_request', to: 'jobs#process_request'
    
    get 'jobs/mets_data/:job_id/:api_key' , to: 'jobs#mets_data'
    get 'jobs/mets_dmdid_attribute/:job_id/:group/:api_key' , to: 'jobs#mets_dmdid_attribute'
    

    get 'jobs/get_next_w_status/:status/:api_key' , to: 'jobs#get_next_w_status'
    get 'workflows/change_status/:job_id/:status/:api_key' , to: 'workflows#change_status'
    get 'jobs/quarantine_job/:job_id/:message_key/:api_key' , to: 'jobs#quarantine_job'
    
    get 'jobs/get_small_work_images/:job_id/:startnr/:count/:api_key' , to: 'jobs#get_small_work_images'
    post 'jobs/update_page_info' , to: 'jobs#update_page_info'
    get 'jobs/get_image/:job_id/:page/:api_key', to: 'jobs#get_image'
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

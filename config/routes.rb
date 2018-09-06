Rails.application.routes.draw do
  mount_ember_app :frontend, to: "/"
  apipie
  resources :session
  get 'setup', to: 'setup#index'
  post 'setup', to: 'setup#update'
  get 'config', to: 'setup#configindex'

  # Assets routes
  get 'assets/work_order/:asset_id', to: 'assets#work_order'
  get 'assets/job_pdf/:asset_id', to: 'assets#job_pdf'
  get 'assets/job_file/:asset_id', to: 'assets#job_file'
  get 'assets/file', to: 'assets#file'
  get 'assets/thumbnail', to: 'assets#thumbnail'

  namespace :api, :defaults => {:format => :json} do
    get 'check_connection' , to: 'process#check_connection'

    # Config API
    get 'config/roles', to: 'config#role_list'
    get 'config/status_list', to: 'config#status_list'
    get 'config/states', to: 'config#state_list'
    get 'config/cas_url', to: 'config#cas_url'
    get 'config/version_info', to: 'config#version_info'

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
    get 'queued_jobs', to: 'process#queued_jobs'
    get 'process/:job_id', to: 'process#update_process'

    # Publication log API
    resources :publication_log

    resources :flows

    resources :queue_manager

    post 'script', to: 'script#create'
    get 'script/:id', to: 'script#show'
  end

end

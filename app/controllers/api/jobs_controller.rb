
class Api::JobsController < Api::ApiController
  before_filter :check_params
  before_filter -> { validate_rights 'manage_jobs' }, only: [:create, :update, :destroy, :restart, :quarantine, :unquarantine, :new_flow_step]
  respond_to :json, :pdf
  require 'pp'
  

  resource_description do
    short 'Job object manager'
  end

  api :GET, '/jobs', 'Returns a list of jobs based on query'
  param :page, :number, desc: "Declares which page of search result should be displayed (default: 1)", default: 1
  param :query, String, desc: "Return jobs matching search string"
  description "Returns a list of jobs based on given query parameters. These job objects are minimized for performance reasons, to retrieve a complete job object see /jobs/:id ."
  example '{"jobs":[{"id":1001002,"name":null,"title":"Water and water pollution handbook.","display":"Water and water pollution handbook.","source_label":"Libris","catalog_id":1234,"breadcrumb_string":"Projekt / OCR-projektet","treenode_id":6}]}'.pretty_json
  see 'jobs#show'
  def index
    jobs = Job.all.eager_load(:treenode).eager_load(:flow_steps)
    pagination = {}
    metaquery = {}
    metaquery[:query] = params[:query] # Not implemented yet

    if params.has_key?(:node_id)
      jobs = jobs.where(treenode_id: params[:node_id])
    end

    if params[:query].present?
      Job.index_jobs
      jobs = jobs.where("search_title LIKE ?", "%#{params[:query].norm}%")
    end

    # Filter by source
    if params.has_key?(:sources) && params[:sources] != []
      jobs = jobs.where(source: params[:sources])
    end

    
    # Filter by quarantined flag if it exists and is a boolean value
    if params.has_key?(:quarantined) && params[:quarantined] != ''
      # If parameter is a string, cast to boolean
      value = params[:quarantined]
      value = value.to_boolean if params[:quarantined].is_a? String

      jobs = jobs.where(quarantined: value)
    end

    # Filter by status
    #if params.has_key?(:status) && !params[:status].blank?
    #  jobs = jobs.where(status: params[:status])
    #end

    # Filter by state
    if params.has_key?(:state) && !params[:state].blank?
      jobs = jobs.where(state: params[:state])
    end

    metaquery[:total] = jobs.count
    if !jobs.empty?
      tmp = jobs.paginate(page: params[:page])
      if tmp.current_page > tmp.total_pages
        jobs = jobs.paginate(page: 1)
      else
        jobs = tmp
      end
      jobs = jobs.order(:id).reverse_order
      pagination[:pages] = jobs.total_pages
      pagination[:page] = jobs.current_page
      pagination[:next] = jobs.next_page
      pagination[:previous] = jobs.previous_page
      pagination[:per_page] = jobs.per_page
    else
      pagination[:pages] = 0
      pagination[:page] = 0
      pagination[:next] = nil
      pagination[:previous] = nil
      pagination[:per_page] = nil
    end

    @response[:jobs] = jobs.as_json(list: true)
    @response[:meta] = {query: metaquery, pagination: pagination}

    render_json
  end
  
  api :GET, '/jobs/:id', 'Returns a single complete Job object'
  description 'Returns a complete Job object, including workflow and log entries.'
  example '{"job":{"status":"waiting_for_digitizing","id":1001002,"name":null,"catalog_id":1234,"title":"Water and water pollution handbook.","author":null,"deleted_at":null,"created_by":null,"updated_by":null,"xml":"\u003c?xml version=\"1.0\" encoding=\"UTF-8\"?\u003e\u003cxsearch xmlns:marc=\"http://www.loc.gov/MARC21/slim\" to=\"1\" ...","quarantined":false,"comment":null,"object_info":null,"search_title":null,"metadata":"{\"type_of_record\":\"am\"}","created_at":"2015-02-20T15:14:12.254Z","updated_at":"2015-02-20T15:14:12.254Z","source":"libris","treenode_id":6,"copyright":false,"display":"Water and water pollution handbook.","source_label":"Libris","breadcrumb":[{"id":1,"name":"Projekt"},{"id":6,"name":"OCR-projektet"}],"activities":[{"job_id":1001002,"id":7276,"username":"admin","event":"CREATE","message":"Activity has been created","created_at":"2015-02-20T15:14:12.259Z","updated_at":"2015-02-20T15:14:12.259Z"}]}}'.pretty_json
  def show
    begin
      job = Job.find(params[:id])
      if params[:format] == "xml"
        render xml: job.xml
        return
      else
        @response[:job] = job
      end
    rescue
      error_msg(ErrorCodes::REQUEST_ERROR, "Could not find job '#{params[:id]}'")
    end
    render_json
  end

  # Creates a job from given parameter data.
  # The created object is returned in JSON as well as a location header.
  api :POST, '/jobs/', 'Creates a Job object'
  description 'Creates a Job object, base object is created by using /sources/fetch_source_data. This object can be saved as is, except for copyright value which must be assigned (true for restricted use, false for public domain).'
  see 'sources#fetch_source_data'
  example '{"job":{"treenode_id":25, "dc":{}, "source":"libris", "catalog_id":"1234", "title":"Water and water pollution handbook.", "xml":"xml", "metadata":{"type_of_record":"am"}, "is_periodical":false, "source_label":"Libris", "copyright":false, "name":"Test job name"}}'.pretty_json
  def create
    validate_only = params[:validate_only]
    job_params = params[:job]
    job_params[:metadata] = job_params[:metadata].to_json
    if job_params.has_key?(:flow_parameters)
      job_params[:flow_parameters] = job_params[:flow_parameters].to_json
    end
    job_params[:created_by] = @current_user.username
    parameters = ActionController::Parameters.new(job_params)
    job = Job.new(parameters.permit(:name, :title, :author, :metadata, :xml, :source, :catalog_id, :comment, :object_info, :flow_id, :flow_params, :treenode_id, :copyright, :created_by, :status, :quarantined, :message, :priority, :package_metadata, :current_flow_step, :package_location, :flow_parameters))

    # If ID is given, use it for creation
    if params[:force_id]
      job.id = params[:force_id]
    end

    if (!validate_only && !job.save!) || (validate_only && !job.valid?)
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job.", job.errors)
      render_json
      return
    end

    if !validate_only
      job.reload
      job_url = url_for(controller: 'jobs', action: 'create', only_path: true)
      #headers['location'] = "#{job_url}/#{job.id}"
    end
    
    @response[:job] = job
    render_json(201)
  #rescue => e
    #error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job, this is why: [#{e.message}].")
    #render_json
  end

  api :PUT, '/jobs/:id', 'Updates a Job object'
  description 'Updates an existing job object. Only parameters that are to be updated have to be sent to this method, all other fields will remain unchanged.'
  example '{"job":{"copyright":false}}'
  def update
    job = Job.find_by_id(params[:id])
    job_params = params[:job]
    if job_params.has_key?(:metadata)
      job_params[:metadata] = job_params[:metadata].to_json
    end
    if job_params.has_key?(:flow_parameters)
      job_params[:flow_parameters] = job_params[:flow_parameters].to_json
    end
    if job_params.has_key?(:package_metadata)
      job_params[:package_metadata] = job_params[:package_metadata].to_json
    end
    job_params[:created_by] = @current_user.username
    parameters = ActionController::Parameters.new(job_params)
    
    if job.flow_id != job_params[:flow_id] && job_params[:flow_id].present?
      flow_is_changed = true
    end

    if job.update_attributes(parameters.permit(:name, :title, :author, :metadata, :xml, :source, :catalog_id, :comment, :object_info, :flow_id, :flow_params, :treenode_id, :copyright, :created_by, :status, :quarantined, :message, :priority, :package_metadata, :current_flow_step, :flow_parameters))
      if flow_is_changed
        job.change_flow(flow_id: params[:flow_id])
      end
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job.", job.errors)
    end

    render_json
  end

  api :DELETE, '/jobs/:id', 'Deletes a Job object'
  description 'Deletes a Job object. Job deletion is a soft delete, and will only flag object as deleted. To restore a deleted job, set deleted_at flag to null in database'
  def destroy
    job = Job.find_by_id(params[:id])
    
    if job.delete
      job.id = nil
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not delete job with id #{params[:id]}")
    end

    render_json
  end

  api :GET, '/jobs/:id/restart', 'Restarts a job'
  description 'Restarts a job, meaning that the flow steps will be recreated and current flow step be set to the first step. This operation cannot be undone.'
  def restart
    job = Job.find_by_id(params[:id])
    job.created_by = @current_user.username
    job.message = params[:message]
    if params[:recreate_flow] = 'true'
      recreate_flow = true
    else
      recreate_flow = false
    end
    if job.restart(recreate_flow: recreate_flow)
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not restart.", job.errors)
    end

    render_json
  end

  api :GET, '/jobs/:id/quarantine', 'Puts a Job into Quarantine'
  description 'Puts a Job into Quarantine, meaning it will not continue processing until it has been removed from Quarantine'
  param :message, String, desc: "Quarantine message (reason for action)"
  def quarantine
    job = Job.find_by_id(params[:id])
    job.created_by = @current_user.username
    if job.quarantine!(msg: params[:message])
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not quarantine job.", job.errors)
    end
    render_json
  end

  api :GET, '/jobs/:id/unquarantine', 'Takes a Job out of Quarantine'
  description 'Takes a job out of Quarantine state, and sets given flow step number as current flow step. Subsequent flow steps will be recreated.'
  param :step, :number, "Step number of flow step to set as current flow step for job." 
  def unquarantine
    job = Job.find_by_id(params[:id])
    job.created_by = @current_user.username
    if params[:recreate_flow] = 'true'
      recreate_flow = true
    else
      recreate_flow = false
    end
    if job.unquarantine!(step_nr: params[:step].to_i, recreate_flow: recreate_flow)
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not unquarantine job.", job.errors)
    end
    render_json
  end

  api!
  def new_flow_step
    job = Job.find_by_id(params[:id])
    job.created_by = @current_user.username
    if params[:recreate_flow].to_s == 'true'
      if job.recreate_flow(step_nr: params[:step].to_i)
        @response[:job] = job
      else
        error_msg(ErrorCodes::OBJECT_ERROR, "Could not update flow step for job", job.errors)
      end
    else
      if job.new_flow_step!(step_nr: params[:step].to_i)
        @response[:job] = job
      else
        error_msg(ErrorCodes::OBJECT_ERROR, "Could not update flow step for job", job.errors)
      end
    end
    render_json
  end


  # Checks if job exists, and sets @job variable. Otherwise, return error.
  private
  def check_params
    return unless check_job_id
  end

  #Check job_id
  def check_job_id
    if params[:job_id]
      @job = Job.where(id: params[:job_id]).first
      if @job.nil?
        error_msg(ErrorCodes::OBJECT_ERROR, "Could not find job '#{params[:job_id]}'")
        render_json
        return false
      end
    end
    return true
  end

end

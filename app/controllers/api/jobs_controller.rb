
class Api::JobsController < Api::ApiController
  before_filter :check_params
  before_filter -> { validate_rights 'manage_jobs' }, only: [:create, :update, :destroy, :restart, :quarantine, :unquarantine]
  respond_to :json, :pdf
  require 'pp'
  

  resource_description do
    short 'Job object manager'
  end

  api :GET, '/jobs', 'Returns a list of jobs based on query'
  formats [:json]
  param :page, String, :desc => "Decides which page of pagination should be returned"
  param :query, String, :desc => "Return jobs matching search string"
  description "Returns a list of all jobs"
  example '{"jobs":[{"id":1001002,"name":null,"title":"Water and water pollution handbook.","display":"Water and water pollution handbook.","source_label":"Libris","catalog_id":1234,"breadcrumb_string":"Projekt / OCR-projektet","treenode_id":6}]}'.pretty_json
  def index
    jobs = Job.all
    pagination = {}
    metaquery = {}
    metaquery[:query] = params[:query] # Not implemented yet

    if params.has_key?(:node_id)
      jobs = jobs.where(treenode_id: params[:node_id])
    end

    if params[:query]
      Job.index_jobs
      jobs = jobs.where("search_title LIKE ?", "%#{params[:query].norm}%")
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
  
  api :GET, '/jobs/id', 'Returns a single Job object'
  formats [:json]
  description 'Returns a job object'
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
  formats [:json]
  description 'Creates a Job object'
  def create
    validate_only = params[:validate_only]
    job_params = params[:job]
    job_params[:metadata] = job_params[:metadata].to_json
    job_params[:created_by] = @current_user.username
    job_params[:flow] ||= APP_CONFIG["default_workflow"]
    parameters = ActionController::Parameters.new(job_params)
    job = Job.new(parameters.permit(:name, :title, :author, :metadata, :xml, :source, :catalog_id, :comment, :object_info, :flow_id, :flow_params, :treenode_id, :copyright, :created_by, :status, :quarantined, :message, :package_metadata, :flow, :current_flow_step))

    # If ID is given, use it for creation
    if params[:force_id]
      job.id = params[:force_id]
    end

    if (!validate_only && !job.save) || (validate_only && !job.valid?)
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job.", job.errors)
    end

    if !validate_only
      job.reload
      job_url = url_for(controller: 'jobs', action: 'create', only_path: true)
      headers['location'] = "#{job_url}/#{job.id}"
    end
    
    @response[:job] = job
    render_json(201)
  rescue => e
    error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job, this is why: [#{e.message}].")
    render_json
  end

  api!
  def update
    job = Job.find_by_id(params[:id])
    job_params = params[:job]
    job_params[:metadata] = job_params[:metadata].to_json
    job_params[:created_by] = @current_user.username
    parameters = ActionController::Parameters.new(job_params)
    if job.update_attributes(parameters.permit(:name, :title, :author, :metadata, :xml, :source, :catalog_id, :comment, :object_info, :flow_id, :flow_params, :treenode_id, :copyright, :created_by, :status, :quarantined, :message, :package_metadata, :flow, :current_flow_step))
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job.", job.errors)
    end

    render_json
  end

  api!
  def destroy
    job = Job.find_by_id(params[:id])
    
    if job.delete
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not delete job with id #{params[:id]}")
    end

    render_json
  end

  api!
  def restart
    job = Job.find_by_id(params[:id])
    job.created_by = @current_user.username
    job.message = params[:message]
    if job.restart
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not restart.", job.errors)
    end

    render_json
  end

  api!
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

  api!
  def unquarantine
    job = Job.find_by_id(params[:id])
    job.created_by = @current_user.username
    if job.unquarantine!(flow_step: params[:step])
      @response[:job] = job
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not unquarantine job.", job.errors)
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

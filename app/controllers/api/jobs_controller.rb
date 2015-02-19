
class Api::JobsController < Api::ApiController
  before_filter :check_key
  before_filter :check_params
  before_filter -> { validate_rights 'manage_jobs' }, only: [:create, :update, :destroy]

  # Returns all jobs
  def index
    jobs = Job.all
    pagination = {}
    if !jobs.empty?
      tmp = jobs.paginate(page: params[:page])
      if tmp.current_page > tmp.total_pages
        jobs = jobs.paginate(page: 1)
      else
        jobs = tmp
      end
      jobs = jobs.order(:name)
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
    metaquery = {}
    metaquery[:query] = params[:query] # Not implemented yet
    metaquery[:total] = jobs.count

    @response[:jobs] = jobs.as_json(list: true)
    @response[:meta] = {query: metaquery, pagination: pagination}

    render_json
  end

  def show
    begin
      job = Job.find(params[:id])
      @response[:job] = job
    rescue
      error_msg(ErrorCodes::REQUEST_ERROR, "Could not find job '#{params[:id]}'")
    end
    render_json
  end

  # Returns the metadata for a given job
  def job_metadata
    begin
      @response[:data] = JSON.parse(@job.metadata)
    rescue
      error_msg(ErrorCodes::DATA_ACCESS_ERROR, "Could not get metadata for job '#{params[:job_id]}'")
    end
    render_json
  end

  # Returns the metadata for a given job
  def job_metadata
    begin
      @response[:data] = JSON.parse(@job.metadata)
    rescue
      error_msg(ErrorCodes::DATA_ACCESS_ERROR, "Could not get metadata for job '#{params[:job_id]}'")
    end
    render_json
  end

  # Updates metadata for a specific key
  def update_metadata
    begin
      @job.update_metadata_key(params[:key], params[:metadata])
    rescue
      error_msg(ErrorCodes::DATA_ACCESS_ERROR, "Could not update metadata for job '#{params[:job_id]}'")
    end
    render_json
  end



  # Creates a job from given parameter data.
  # The created object is returned in JSON as well as a location header.
  def create
    job_params = params[:job]
    job_params[:metadata] = job_params[:metadata].to_json
    job_params[:created_by] = @current_user.username
    parameters = ActionController::Parameters.new(job_params)
    job = Job.new(parameters.permit(:name, :title, :author, :metadata, :xml, :source, :catalog_id, :comment, :object_info, :flow_id, :flow_params, :treenode_id, :copyright, :created_by, :status))
    
    # If ID is given, use it for creation
    if params[:force_id]
      job.id = params[:force_id]
    end
    
    if !job.save
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job.", job.errors)
    end

    job_url = url_for(controller: 'jobs', action: 'create', only_path: true)
    headers['location'] = "job_url/#{job.id}"
    @response[:job] = job
    render_json(201)
  rescue Exception => e
    pp "Could not save job, this is why: [#{e.message}]."
    error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job, this is why: [#{e.message}].")
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

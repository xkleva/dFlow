
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

  # Creates a job from given parameter data
  def create_job
    job_params = params[:data]
    job_params[:metadata] = job_params[:metadata].to_json
    job_params[:created_by] = @current_user.username
    parameters = ActionController::Parameters.new(job_params)
    job = Job.create(parameters.permit(:name, :title, :author, :metadata, :xml, :source_id, :catalog_id, :comment, :object_info, :flow_id, :flow_params, :created_by))

    if !job.save
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job with name '#{job[:name]}", job.errors)
    end
    render_json
  end

    # Creates a job from given parameter data
  def create
    #   headers['location'] = "/api/jobs/#{obj.id}"
    #   #headers['location'] = "#{:job_url}"
    #   status = 201
    pp "==========================="
    pp params
    pp "==========================="
    job_params = params['job']
    job_params[:metadata] = job_params[:metadata].to_json
    parameters = ActionController::Parameters.new(job_params)
    pp "-+-+-+-+-+-+-+-+"
    pp parameters
    pp "-+-+-+-+-+-+-+-+"
    #job = Job.new()
    job = Job.create(parameters.permit(:name, :title, :author, :metadata, :xml, :source, :catalog_id, :comment, :object_info, :flow_id, :flow_params, :treenode_id))

    if !job.save
      #error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job with name '#{job[:name]}", job.errors)
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job...", job.errors)
    end
    render_json
  rescue Exception => e
    #pp "Error in fetch_from_libris #{e.message}"
    pp "A terrible error occurred: '#{e.message}'.    Please try harder!"
    #error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job with name '#{job[:name]}", job.errors)
    error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job...")
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

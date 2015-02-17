
class Api::JobsController < Api::ApiController
	before_filter :check_key
	before_filter :check_params


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

    @response[:jobs] = jobs
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

	# Updates metadata for a specific key
	def update_metadata
		begin
			@job.update_metadata_key(params[:key], params[:metadata])
		rescue
			error_msg(ErrorCodes::DATA_ACCESS_ERROR, "Could not update metadata for job '#{params[:job_id]}'")
		end
		render_json
	end

	# Returns a job to work on for given process unless too many processes are already running
	def process_request
		job = nil

		return unless process_startable #Return if process cannot start for some reason

		# Find job that is PENDING for method
		job = @process.first_pending_job

		if job.nil?
			error_msg(ErrorCodes::QUEUE_ERROR, "No jobs currently waiting for process with id '#{params[:process_id]}", @process.errors)
		else
			@response[:data] = {job_id: job.id, params: job.current_entry.flow_step.params}
		end
		render_json
	end

	# Initiates given process for given job
	def process_initiate

	  return unless process_startable # Return if process cannot start for some reason

	  if !@process.update_state_for_job(@job.id, "STARTED")
	  	error_msg(ErrorCodes::DATA_ACCESS_ERROR, "Could not change state for job with id '#{params[:job_id]}'", @process.errors)
	  end
	  render_json
	end

	# Sets a process for given job and process_method as done
	def process_done
		if !@process.update_state_for_job(@job.id, "DONE")
			error_msg(ErrorCodes::DATA_ACCESS_ERROR, "Could not change state for job with id '#{params[:job_id]}", @process.errors)
		end
		render_json
	end

	# Contains progress information about given job and process
	def process_progress
		if !@process.update_progress_for_job(@job.id, params[:progress_info])
			error_msg(ErrorCodes::DATA_ACCESS_ERROR, "Could not update progress information for job with id '#{params[:job_id]}", @process.errors)
		end
		render_json
	end

	# Creates a job from given parameter data
	def create_job
		job_params = params[:data]
		job_params[:metadata] = job_params[:metadata].to_json
		parameters = ActionController::Parameters.new(job_params)
		job = Job.create(parameters.permit(:name, :title, :author, :metadata, :xml, :source_id, :catalog_id, :comment, :object_info, :flow_id, :flow_params))

		if !job.save
			error_msg(ErrorCodes::OBJECT_ERROR, "Could not save job with name '#{job[:name]}", job.errors)
		end
		render_json
	end

	# Checks if job exists, and sets @job variable. Otherwise, return error.
	private
	def check_params
		return unless check_job_id
		return unless check_process_id
		return unless check_job_and_process
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

	#Check process_id
	def check_process_id
		if params[:process_code]
			@process = ProcessModel.find_on_code(params[:process_code])
			if !@process
				error_msg(ErrorCodes::OBJECT_ERROR, "Could not find process with id '#{params[:process_id]}'")
				render_json
				return false
			end
		end
		return true
	end

	#If both job and process are set, check if they are valid together
	def check_job_and_process
		if params[:job_id] && params[:process_code]
			if @job.current_entry.flow_step.process_id != @process.id
				error_msg(ErrorCodes::QUEUE_ERROR, "Job with id '#{params[:process_code]}' is not currently working on #{params[:process_code]}")
				render_json
				return false
			end
		end
		return true
	end

	# Checks if process is startable and sets proper error messages if not
	def process_startable
		# Check if the allowed amount of processes are already running
		if !@process.startable?
			error_msg(ErrorCodes::QUEUE_ERROR, "Too many running processes with id '#{params[:process_id]}", @process.errors)
			render_json
			return false
		end
		return true
	end

end


class Api::JobsController < Api::ApiController
	before_filter :check_key
	before_filter :check_params


	# Returns the metadata for a given job
	def job_metadata
		begin
			@response[:data] = JSON.parse(@job.metadata)
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		rescue
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("DATA_ACCESS_ERROR", "Could not get metadata for job '#{params[:job_id]}'")
		end
		render json: @response
	end

	# Updates metadata for a specific key
	def update_metadata
		begin
			@job.update_metadata_key(params[:key], params[:metadata])
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		rescue
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("DATA_ACCESS_ERROR", "Could not update metadata for job '#{params[:job_id]}'")
		end
		render json: @response
	end

	# Returns a job to work on for given process unless too many processes are already running 
	def process_request
		job = nil

		# Check if the allowed amount of processes are already running
		if !@process.startable?
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("QUEUE_ERROR", "Too many running processes with id '#{params[:process_id]}", @process.errors)
			render json: @response
			return
		end

		# Find job that is PENDING for method
		job = @process.first_pending_job
		
		if job.nil?
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("QUEUE_ERROR", "No jobs currently waiting for process with id '#{params[:process_id]}", @process.errors)
		else
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
			@response[:data] = {job_id: job.id, params: job.current_entry.flow_step.params}
		end

		render json: @response
	end

	# Initiates given process for given job
	def process_initiate
		# Check if the allowed amount of processes are already running
		if !@process.startable?
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("QUEUE_ERROR", "Too many running processes with id '#{params[:process_id]}", @process.errors)
			render json: @response
			return
		end

		if @process.update_state_for_job(@job.id, "STARTED")
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		else
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("DATA_ACCESS_ERROR", "Could not change state for job with id '#{params[:job_id]}'", @process.errors)
		end
		render json: @response
	end

	# Sets a process for given job and process_method as done
	def process_done
		if @process.update_state_for_job(@job.id, "DONE")
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		else
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("DATA_ACCESS_ERROR", "Could not change state for job with id '#{params[:job_id]}", @process.errors)
		end
		render json: @response
	end

	# Contains progress information about given job and process
	def process_progress
		if @process.update_progress_for_job(@job.id, params[:progress_info])
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		else
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("DATA_ACCESS_ERROR", "Could not update progress information for job with id '#{params[:job_id]}", @process.errors)
		end
		render json: @response
	end

	# Creates a job from given parameter data
	def create_job
		job_params = params[:data]
		job_params[:metadata] = job_params[:metadata].to_json
		parameters = ActionController::Parameters.new(job_params)
		job = Job.create(parameters.permit(:name, :title, :author, :metadata, :xml, :source_id, :catalog_id, :comment, :object_info, :metadata, :flow_id, :flow_params))

		if job.save
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		else
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not save job with name '#{job[:name]}", job.errors)
		end
		render json: @response
	end

	# Checks if job exists, and sets @job variable. Otherwise, return error.
	private
	def check_params
		@response ||= {}
		
		#Check job_id
		if params[:job_id]
			@job = Job.where(id: params[:job_id]).first
			if @job.nil?
				@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find job '#{params[:job_id]}'")
				render json: @response
				return
			end
		end

		#Check process_id
		if params[:process_code]
			@process = ProcessModel.find_on_code(params[:process_code])
			if !@process
				@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find process with id '#{params[:process_id]}'")
				render json: @response
				return
			end
		end

		#If both job and process are set, check if they are valid together
		if params[:job_id] && params[:process_code]
			if @job.current_entry.flow_step.process_id != @process.id
				@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("QUEUE_ERROR", "Job with id '#{params[:process_code]}' is not currently working on #{params[:process_code]}")
				render json: @response
				return
			end
		end
	end

end
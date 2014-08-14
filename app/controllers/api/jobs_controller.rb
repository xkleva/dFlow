
class Api::JobsController < Api::ApiController
	before_filter :check_key
	before_filter :check_params

	# Checks if job exists, and sets @job variable. Otherwise, return error.
	def check_params
		@response ||= {}
		
		#Check job_id
		if params[:job_id]
			@job = Job.where(id: params[:job_id]).first
			if @job.nil?
				@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find job '#{params[:job_id]}'")
				render json: @response
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
	end

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
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("QUEUE_ERROR", "Too many running processes with id '#{params[:process_id]}")
			render json: @response
			return
		end

		# Find job that is PENDING for method
		job = @process.first_pending_job
		
		if job.nil?
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("QUEUE_ERROR", "No jobs currently waiting for process with id '#{params[:process_id]}")
		else
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
			@response[:data] = {job_id: job.id}
		end

		render json: @response
	end

	# Initiates given process for given job
	def initiate
		
	end

end
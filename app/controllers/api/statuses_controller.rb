class Api::StatusesController < Api::ApiController
  before_filter :check_job
  before_filter -> { validate_rights 'manage_jobs' }

  resource_description do
    short 'Status update manager - Updates job statuses'
  end

  # Sets new status if allowed
  def new
    to_status = Status.find_by_name(params[:status])
    new_status(to_status.previous_status, to_status)
  end

  # Completes status and changes to next status
  def complete
    from_status = Status.find_by_name(params[:status])
    new_status(from_status, from_status.next_status)
  end

  private 

  def check_job
    @job = Job.find_by_id(params[:id])
    
    if @job.nil?
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find a job with id #{params[:id]}")
      render_json
      return
    end
  end

  # Changes status
  def new_status(from_status, to_status)

    # If job is already in new status, return success
    if @job.status == to_status.name
      @response[:job] = @job
      render_json
      return
    end

    # If job is not in from_status, return
    return if from_status && !ensure_status(from_status)

    @job.created_by = @current_user.username
    @job.switch_status(to_status)

    if !@job.valid? || !@job.save
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not save job", @job.errors)
    else
      @response[:job] = @job
    end

    render_json
  end

  # Makes sure that job exists and is in correct status
  def ensure_status(status)

    if @job.status != status.name
      error_msg(ErrorCodes::QUEUE_ERROR, "Job is in wrong status: #{@job.status} instead of #{status.name}")
      render_json
      return false
    else
      return true
    end
    
  end

end
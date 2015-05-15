class Api::ProcessController < Api::ApiController

  before_filter -> { validate_rights 'manage_jobs' }, only: [:request_job, :update_process, :check_connection]

  # Return 200 if connection is valid
  def check_connection
    @response[:msg] = "Connection successful!"
    render_json
  end

  # Returns a job for given code if any is applicable
  def request_job
    code = params[:code]
    process = APP_CONFIG["processes"].find{|x| x["code"] == code}

    # If process does not exist in config, return error
    if !process
      @response[:error] = "No such process code found: #{code}"
      render_json
      return
    end

    # Check if there are jobs that are in process status
    running_jobs = Job.where(status: Status.find_by_name(process["status"]).next_status.name).where(quarantined: false).where(deleted_at: nil)

    if !running_jobs.empty?
      @response[:msg] = "There are jobs running for process #{code}"
      render_json
      return
    end
    
    # Find a job with proper status according to process
    job = Job.where(status: process["status"]).where(quarantined: false).where(deleted_at: nil).first

    if !job
      @response[:msg] = "No job found to process for code #{code}"
      render_json
      return
    end

    job.created_by = @current_user.username
    # Switch job status before it is returned
    job.switch_status(job.status_object.next_status)
    if job.save
      @response[:job] = job.as_json
      render_json
      return
    else
      @response[:error] = "Could not update status of job with id #{job.id}"
      render_json
      return
    end

    render_json
  end

  # Takes a process update and updates job accordingly
  def update_process
    job = Job.find_by_id(params[:job_id])

    if !job
      @response[:error] = "Could not find job with id #{params[:job_id]}"
      render_json
      return
    end

    job.created_by = @current_user.username

    # If process is successful, update status
    if params[:status] == 'success'
      job.switch_status(job.status_object.next_status)
      if !params[:msg].blank?
        job.update_attributes(process_message: params[:msg])
      end
      job.save
    end

    # If process failed, quarantine job with message
    if params[:status] == 'fail'
      job.update_attributes(quarantined: true, message: params[:msg])
    end

    # If process is sending a progress report, save message
    if params[:status] == 'progress'
      if !params[:msg].blank?
        job.update_attributes(process_message: params[:msg])
      end
    end

    @response[:job] = job

    render_json
  end
end
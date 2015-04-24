class Api::ProcessController < Api::ApiController

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

    # Find a job with proper status according to process
    job = Job.where(status: process["status"]).where(quarantined: false).where(deleted_at: nil).first
    
    # Switch job status before it is returned
    if job.switch_status(job.status_object.next_status)
      @response[:job] = job
      render_json
      return
    else
      @response[:error] = "Could not update status of job with id #{job.id}"
      render_json
      return
    end

    render_json
  end

  def update_process
    job = Job.find(params[:job_id])
  end
end

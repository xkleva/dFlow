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
      error_msg(ErrorCodes::OBJECT_ERROR, "No such process code found: #{code}", job.errors)
      render_json
      return
    end

    # Check if there are jobs that are in process status
    jobs = Job.where(quarantined: false, deleted_at: nil).select(:id)
    running_steps = FlowStep.where(process: process["code"]).where.not(entered_at: nil, started_at: nil).where(finished_at: nil, aborted_at: nil).where(job_id: jobs)
    if !running_steps.empty?
      @response[:msg] = "There are jobs running for process #{code}"
      render_json
      return
    end

    steps = FlowStep.where(process: process["code"]).where.not(entered_at: nil).where(started_at: nil, aborted_at: nil, finished_at: nil).where(job_id: jobs)

    job = nil
    if steps.present?
      job = steps.first.job
    end

    if !job
      @response[:msg] = "No job found to process for code #{code}"
      render_json
      return
    end

    job.created_by = @current_user.username
    # Switch job status before it is returned
    job.flow_step.start!
    if job.save
      @response[:job] = job.as_json
      render_json
      return
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not update status of job with id #{job.id}", job.errors)
      render_json
      return
    end

    render_json
  end

  # Takes a process update and updates job accordingly
  def update_process
    job = Job.find_by_id(params[:job_id])

    if !job
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find job with id #{params[:job_id]}", job.errors)
      render_json
      return
    end

    job.created_by = @current_user.username
    flow_step = job.flow_step
    flow_step.job = job

    # Validate that job is currently on given flow_step
    if flow_step.step != params[:step].to_i
      error_msg(ErrorCodes::QUEUE_ERROR, "Given step number does not correlate to current flow_step, step: #{params[:step]}, job: #{params[:job_id]}, current step: #{flow_step.step}")
      render_json
      return
    end

    # If process is successful, update status
    if params[:status] == 'success'
      if !flow_step.started?
        flow_step.update_attribute('started_at', DateTime.now)
      end
      flow_step.finish!
      job.reload
    end

    # If process failed, quarantine job with message
    if params[:status] == 'fail'
      job.update_attributes(quarantined: true, message: params[:msg])
    end

    # If process is sending a progress report, save message
    if params[:status] == 'progress'
      if !params[:msg].blank?
        job.flow_step.update_attribute('process_msg', params[:msg])
      end
    end

    @response[:job] = job

    render_json
  end
end
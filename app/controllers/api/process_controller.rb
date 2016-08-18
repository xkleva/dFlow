class Api::ProcessController < Api::ApiController

  before_filter -> { validate_rights 'manage_jobs' }, only: [:request_job, :update_process, :check_connection]

  api :GET, '/process/check_connection', 'Check if connection is available'
  description 'Returns 200 and a success message if API is available'
  def check_connection
    @response[:msg] = "Connection successful!"
    render_json
  end

  # Returns a list of jobs waiting to be automatically processed
  def queued_jobs
    steps = FlowStep.queued_steps
    @response[:flow_steps] = steps
    
    limit = APP_CONFIG['queue_manager']['processes']['queue_manager_waitfor_limit'].to_i
    
    @response[:meta] = {
      queue_manager_limit_count: limit,
      queue_manager_limited: QueueManagerPid.queue_manager_limited?
    }
    render_json
  end

  api :GET, '/process/request_job/:code', ' Returns a job for given code'
  description 'Returns a Job where its current flow step has given process code as process name. Returns no job  if a process of given code is currently running, or if there are no applicable jobs'
  def request_job
    code = params[:code]
    process = SYSTEM_DATA["processes"].find{|x| x["code"] == code}

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
    flow_step = job.flow_step
    flow_step.job = job
    # Switch job status before it is returned
    flow_step.start!
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

  api :GET, '/process/:job_id', 'Updated a jobs flow step\'s status'
  description 'Updates a Jobs current flow step\'s status'
  param :step, :number, desc: 'The step number of the current flow step, to verify that given job is in proper flow step', required: true
  param :status, String, desc: 'The status of the update, one of: [success, fail, progress]', required: true
  param :msg, String, desc: 'Sets a message for update, i.e. progress message'
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

    # If process is started, start if possible
    if params[:status] == 'start'
      if flow_step.started?
        error_msg(ErrorCodes::QUEUE_ERROR, "Given step number is already started: #{params[:step]}, job: #{params[:job_id]}")
        render_json
        return
      else
        flow_step.start!
      end
    end

    # If process is successful, finish and go to next step
    if params[:status] == 'success'
      if !flow_step.started?
        flow_step.update_attribute('started_at', DateTime.now)
      end
      flow_step.finish!
      job.reload
    end

    # If process failed, quarantine job with message
    if params[:status] == 'fail'
      job.quarantine!(msg: params[:msg])
    end

    # If process is sending a progress report, save message
    if params[:status] == 'progress'
      if !params[:msg].blank?
        job.flow_step.update_attribute('status', params[:msg])
      end
    end

    @response[:job] = job

    render_json
  end
end

#Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/sources/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/adapters/*.rb")].each { |f| require f }

class QueueManager
  QUEUE_MANAGER_CONFIG = APP_CONFIG['queue_manager'].merge(SYSTEM_DATA['queue_manager'])

  def self.run(loop: true)
    DfileApi.logger = QueueManager.logger
    if QueueManagerPid.can_start?
      QueueManagerPid.start(pid: Process.pid)
    end
    while(true) do
      sleep_time = 10
      
      # Check if system things there is a running qm, abort if not
      running_qm = QueueManagerPid.running_qm
      if !running_qm
        logger.fatal "Process #{Process.pid} tried to run, but was not started"
        return
      end
      # Check if PID exists and is mine
      if running_qm.pid != Process.pid
        logger.fatal "PID #{running_qm.pid} doesn't match my process #{Process.pid}, aborting QueueManager"
        return
      end

      # Check if this process should be aborted.
      if running_qm.aborted_at
        running_qm.finish
        logger.fatal "QueueManager was told to abort gracefully."
        return
      end

      if !QueueManagerPid.can_run?(pid: Process.pid)
        running_qm.finish
        logger.fatal "QueueManager was not allowed to run. Aborting..."
        return
      end
      
      job = get_job_waiting_for_automatic_process
      if job
        if job.flow_step && job.flow_step.finished_at
          job.quarantine!(msg: "Error. FlowStep #{job.current_flow_step} already finished at #{job.flow_step.finished_at}")
          return
        end
        logger.info "Starting #{job.flow_step.process} for job #{job.id}"
        execute_process(job: job)
        logger.info "Done processing, repeating"
        sleep_time = 3
      else
        logger.debug "No job to process at this time"
      end

      if !loop 
        return
      end
      sleep sleep_time
    end

  end

  # Returns a single job with a configured automatic process waiting
  def self.get_job_waiting_for_automatic_process
    waitfor_processes = SYSTEM_DATA["processes"].select { |x| x["state"] == "WAITFOR"}.map {|x| x["code"]}
    steps = FlowStep.joins(:job).where.not(entered_at: nil).where(finished_at: nil, aborted_at: nil)
    steps = steps.where('jobs.quarantined = ? and jobs.deleted_at is ? and jobs.state != ?', false, nil, "FINISH")
    steps = steps.where('started_at IS NULL OR process IN (?)', waitfor_processes)
    steps = steps.order('jobs.priority asc, flow_steps.updated_at asc')

    waitfor_limit = APP_CONFIG['queue_manager']['processes']['queue_manager_waitfor_limit'].to_i
    logger.info "WAITFOR: Limit: #{waitfor_limit}"
    if waitfor_limit > 0
      waitfor_count = FlowStep.queued_steps(process_states: 'WAITFOR').count
      logger.info "WAITFOR: Count: #{waitfor_count}"
      if waitfor_count >= waitfor_limit
        steps = steps.where("process IN (?)", waitfor_processes)
        logger.info "WAITFOR: Steps: #{steps.map { |x| [x["job_id"], x["state"], x["code"]]}}"
      end
    end
    
    processes = SYSTEM_DATA['processes'].select {|x| ['PROCESS', 'WAITFOR'].include? x['state']}.map {|x| x['code']}
    automatic_steps = steps.select {|x| processes.include? x.process}
    if automatic_steps.empty?
      return
    end

    # Run process for first job
    job = automatic_steps.first.job
    job.created_by = "QueueManager"
    
    return job
  end

  # Starts correct process for chosen job
  def self.execute_process(job:)

    process = job.flow_step.process
    if job.flow_step.start!(username: process)
      qm = QueueManagerPid.running_qm
      qm.update_attribute(:last_flow_step_id, job.flow_step.id)
      case job.flow_step.state
      when "PROCESS"
        process_runner(job: job, process_object: Object.const_get(job.flow_step.process.downcase.camelize))
      when "WAITFOR"
        waitfor_runner(job: job, waitfor_object: Object.const_get(job.flow_step.process.downcase.camelize))
      else
        logger.fatal "Couldn't find process!"
        job.quarantine!(msg: "Couldn't find process!")
      end
    else
      logger.fatal "Couldn't start process!"
      job.quarantine!(msg: "Couldn't start process!")
    end
  rescue StandardError => e
    logger.fatal e.message + " " + e.backtrace.inspect
    job.quarantine!(msg: e.message)
  end

  # Runs a given process for a given job
  def self.process_runner(job:, process_object:, logger: self.logger)
    params = job.flow_step.parsed_params || {}
    params = params.symbolize_keys
    params[:job] = job
    params[:logger] = logger
    process_object.run(params.except!(:start, :end))
    job.flow_step.finish!(username: job.flow_step.process)
  rescue StandardError => e
    logger.fatal e.message + " " + e.backtrace.inspect
    job.quarantine!(msg: e.message)
  end


  def self.waitfor_runner(job:, waitfor_object:, logger: self.logger)
    params = job.flow_step.parsed_params || {}
    params = params.symbolize_keys
    params[:job] = job
    params[:logger] = logger
    result = waitfor_object.run(params.except!(:start, :end))
    if result == true
      job.flow_step.finish!(username: job.flow_step.process)
    else
      job.flow_step.touch
      logger.info "Process not done"
    end
  rescue StandardError => e
    logger.fatal e.message + " " + e.backtrace.inspect
    job.quarantine!(msg: e.message)
  end

  # Creates a logger object
  def self.logger
#    @@logger ||= Logger.new(STDOUT)
    @@logger ||= Logger.new("#{Rails.root}/log/queue_manager.log")
    @@logger.level = ENV['LOG_LEVEL'].to_i || Logger::INFO
    @@logger
  end


end

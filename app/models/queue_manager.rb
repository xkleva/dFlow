#Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/sources/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/adapters/*.rb")].each { |f| require f }

class QueueManager
  QUEUE_MANAGER_CONFIG = APP_CONFIG['queue_manager'].merge(SYSTEM_DATA['queue_manager'])

  def self.run(loop: true)
    DfileApi.logger = QueueManager.logger
    while(true) do
      # Check if PID file exists
      pid_file = Pathname.new(QUEUE_MANAGER_CONFIG['pid_file_location'])

      # If PID file doesn't exist, exit
      if !pid_file.exist?
        logger.warn "No PID file exists, aborting QueueManager"
        return
      end

      # If PID is not current PID, exit
      current_pid = File.open(pid_file.to_s).read.to_s.strip
      if current_pid != Process.pid.to_s
        logger.fatal "PID #{current_pid} - from file #{pid_file} doesn't match my process #{Process.pid}, aborting QueueManager"
        return
      end

      job = get_job_waiting_for_automatic_process
      if job
        logger.info "Starting #{job.flow_step.process} for job #{job.id}"
        execute_process(job: job)
        logger.info "Done processing, repeating"
      else
        logger.debug "No job to process at this time"
      end

      if !loop 
        return
      end
      sleep 10
    end

  end

  # Returns a single job with a configured automatic process waiting
  def self.get_job_waiting_for_automatic_process
      job_ids = Job.where(quarantined: false, deleted_at: nil).where.not(state: "FINISH").select(:id)
      steps = FlowStep.where.not(entered_at: nil).where(finished_at: nil, aborted_at: nil).where(job_id: job_ids)
      steps = steps.where('started_at IS NULL OR process IN (?)', SYSTEM_DATA["processes"].select { |x| x["state"] == "WAITFOR"}.map {|x| x["code"]})
      steps = steps.order(updated_at: :asc)

      processes = SYSTEM_DATA['processes'].select {|x| ['PROCESS', 'WAITFOR'].include? x['state']}.map {|x| x['code']}
      automatic_steps = steps.select {|x| processes.include? x.process}
      if automatic_steps.empty?
        return
      end

      # Run process for first job
      job = automatic_steps.first.job
      return job
  end

  # Starts correct process for chosen job
  def self.execute_process(job:)

    process = job.flow_step.process
    if job.flow_step.start!(username: process)

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
    process_object.run(params)
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
    result = waitfor_object.run(params)
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
    #@@logger ||= Logger.new(STDOUT)
    @@logger ||= Logger.new("#{Rails.root}/log/queue_manager.log")
    @@logger.level = ENV['LOG_LEVEL'].to_i || Logger::INFO
    @@logger
  end


end

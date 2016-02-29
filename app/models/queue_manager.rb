#Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/sources/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/adapters/*.rb")].each { |f| require f }

class QueueManager
  QUEUE_MANAGER_CONFIG = APP_CONFIG['queue_manager']

  def self.run
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
        logger.fatal "PID file #{current_pid} doesn't match my process #{Process.pid}, aborting QueueManager"
        return
      end

      job = get_job_waiting_for_automatic_process
      if job
        logger.info "Starting #{job.flow_step.process} for job #{job.id}"
        execute_process(job: job)
        logger.info "Done processing, repeating"
      else
        logger.debug "No job to process at this time"
        sleep 10
      end
    end

  end

  # Returns a single job with a configured automatic process waiting
  def self.get_job_waiting_for_automatic_process
      job_ids = Job.where(quarantined: false, deleted_at: nil).where.not(state: "FINISH").select(:id)
      steps = FlowStep.where.not(entered_at: nil).where(started_at: nil, finished_at: nil, aborted_at: nil).where(job_id: job_ids)

      processes = APP_CONFIG['processes'].select {|x| x['state'] == 'PROCESS'}.map {|x| x['code']}
      automatic_steps = steps.select {|x| processes.include? x.process}
      if automatic_steps.empty?
        logger.info "There are no jobs to process at this time."
        return
      end

      # Run process for first job
      job = automatic_steps.first.job
      return job
  end

  # Starts correct process for chosen job
  def self.execute_process(job:)

    if job.flow_step.start!
      job.created_by = job.flow_step.process

      case job.flow_step.process
      when "CREATE_METS_PACKAGE"
        process_runner(job: job, process_object: CreateMETSPackage)
      when "PACKAGE_METADATA_IMPORT"
        process_runner(job: job, process_object: ImportPackageMetadata)
      else
        logger.fatal "Couldn't find process!"
        job.quarantine!(msg: "Couldn't find process!")
      end
      logger.info "PROCESS DONE!"
    else
      logger.fatal "Couldn't start process!"
      job.quarantine!(msg: "Couldn't start process!")
    end
  end

  # Runs a given process for a given job
  def self.process_runner(job:, process_object:, logger: self.logger)
    process_object.run(job: job, logger: logger)
    job.flow_step.finish!
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

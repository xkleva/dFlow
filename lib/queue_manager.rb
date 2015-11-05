#Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/helpers/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/sources/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/adapters/*.rb")].each { |f| require f }

class QueueManager
  def self.run
    while(true) do
      # Check if PID file exists
      pid_file = Pathname.new(APP_CONFIG['pid_file_location'])

      # If PID file doesn't exist, exit
      if !pid_file.exist?
        puts "No PID file exists, aborting QueueManager"
        return
      end

      # If PID is not current PID, exit
      current_pid = File.open(pid_file.to_s).read.to_s
      if current_pid != Process.pid.to_s
        puts "PID file #{current_pid} doesn't match my process #{Process.pid}, aborting QueueManager"
        return
      end

      # Fetch jobs which have an automatic process waiting
      job_ids = Job.where(quarantined: false, deleted_at: nil).where.not(state: "FINISH").select(:id)
      steps = FlowStep.where.not(entered_at: nil).where(started_at: nil, finished_at: nil, aborted_at: nil).where(job_id: job_ids)

      processes = APP_CONFIG['processes'].select {|x| x['state'] == 'PROCESS'}.map {|x| x['code']}
      automatic_steps = steps.select {|x| processes.include? x.process}
      if automatic_steps.empty?
        puts "There are no jobs to process at this time."
        return
      end

      # Run process for first job
      job = automatic_steps.first.job
      puts "Starting #{job.flow_step.process} for job #{job.id}"
      QueueManager.new.execute_process(job: job)
      puts "Done processing, repeating"
    end

  end

  # Starts correct process for chosen job
  def execute_process(job:)

    if job.flow_step.start!

      case job.flow_step.process
      when "CREATE_METS_PACKAGE"
        create_mets_package(job: job)
      when "PACKAGE_METADATA_IMPORT"
        import_package_metadata(job: job)
      end
      puts "PROCESS DONE!"
    else
      puts "Couldn't start process!"
    end
  end

  # Creates a METS package
  def create_mets_package(job:)

  end

  # Imports package metadata
  def import_package_metadata(job:)
    @sh = DFlowProcess::ScriptHelper.new
    @dfile_api = DFlowProcess::DFileAPI.new(@sh, "IMPORT_PACKAGE_METADATA")

    puts "running import package metadata"
    images = ImportPackageMetadata::Images.new(dfile_api: @dfile_api, job: job)
    begin
      images.run
    rescue StandardError => e
      job.quarantine!(msg: images.errors.inspect)
    end

    if images.valid?
      # Store metadata information to job
      job.update_attribute('package_metadata', {images: images.images.map(&:as_json), image_count: images.images.size}.to_json)

      # Update progress
      job.flow_step.finish!
    else
      job.quarantine!(msg: images.errors.inspect)
    end

  end

end

namespace :queue_manager do
  desc "Starts a queue manager if process is not already running"
  $rails_rake_task = true
  task run: :environment do

    Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }
    # Load config for queue manager
    PID_FILE_LOCATION = SYSTEM_DATA['queue_manager']['pid_file_location']
    
    QueueManager.logger.info "Checking if a new queuemanager should be started"

    # Check if PID file exists
    pid_file = Pathname.new(PID_FILE_LOCATION)
    if pid_file.exist?
      # If PID file exists, check if process is running
      old_pid = File.open(pid_file.to_s).read
      QueueManager.logger.info "Found existing pid #{old_pid}, checking if it's still running..."

      # TODO: Make this platform independent
      running_process = `ps -p #{old_pid} -o comm=`
      QueueManager.logger.info "Running process: #{running_process}"
      
      if running_process.strip.start_with? "ruby"
        # Process is still running, abort startup of new process
        QueueManager.logger.info "Process #{old_pid} is still running, aborting!"
        next
      else
        # Process is no longer running, delete pid file
        QueueManager.logger.info "Process is no longer running, removing old PID file"
        FileUtils.rm(pid_file)
      end
    end
    
    # Create PID file
    QueueManager.logger.info "Creating new PID file with if #{Process.pid}..."
    file = File.open(PID_FILE_LOCATION, "w:utf-8") do |file|
      file.write(Process.pid)
    end

    # Start QueueManager process
    QueueManager.logger.info "Starting QueueManager process"
    QueueManager.run
  end

end

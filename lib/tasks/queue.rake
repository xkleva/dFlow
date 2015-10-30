namespace :queue do
  desc "Starts a queue manager if process is not already running"
  task run: :environment do
    PID_FILE_LOCATION = APP_CONFIG['pid_file_location']
    
    puts "Checking if a new queuemanager should be started"
    # Check if PID file exists
    pid_file = Pathname.new(PID_FILE_LOCATION)
    if pid_file.exist?
      # If PID file exists, check if process is running
      old_pid = File.open(pid_file.to_s).read
      puts "Found existing pid #{old_pid}, checking if it's still running..."

      running_process = `ps -p #{old_pid} -o comm=`
      puts "Running process: #{running_process}"
      
      if running_process.strip == "ruby"
        # Process is still running, abort startup of new process
        puts "Process #{old_pid} is still running, aborting!"
        next
      else
        # Process is no longer running, delete pid file
        puts "Process is no longer running, removing old PID file"
        FileUtils.rm(pid_file)
      end
    end
    
    # Create PID file
    puts "Creating new PID file with if #{Process.pid}..."
    file = File.open(PID_FILE_LOCATION, "w:utf-8") do |file|
      file.write(Process.pid)
    end

    # Start QueueManager process
    puts "Starting QueueManager process"
    QueueManager.run
  end

end

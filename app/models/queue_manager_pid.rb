class QueueManagerPid < ActiveRecord::Base
  LOGFILE="log/queue_manager.log"
  LOGFILE_LAST_LIMIT=1000
  belongs_to :last_flow_step, class_name: "FlowStep"
  
  validates :pid, presence: true
  validates :started_at, presence: true
  attr_accessor :running_process_mock

  def as_json(options = {})
    super.merge({
        last_flow_step: last_flow_step,
      })
  end

  # Fetch last lines from logfile
  def self.fetch_log_lines(lines: 50)
    return "" if !File.exist?(LOGFILE)
    if lines.to_i > LOGFILE_LAST_LIMIT || lines.to_i < 1
      return ""
    end
    `tail -n #{lines.to_i} #{LOGFILE}`
  end
  
  # A new QueueManager can start if there is no one running already
  def self.can_start?
    return false if running_qm
    return true
  end

  # A QueueManager can only be stopped if it is active
  def self.can_stop?
    return true if active_qm
    return false
  end
  
  # If QueueManager has limited number of WAITFOR processes,
  # check if the limit is reached.
  def self.queue_manager_limited?
    waitfor_limit = APP_CONFIG['queue_manager']['processes']['queue_manager_waitfor_limit'].to_i
    return false if waitfor_limit <= 0

    waitfor_count = FlowStep.queued_steps(process_states: 'WAITFOR').count
    if waitfor_count >= waitfor_limit
      return true
    end
    return false
  end
  
  # If there is no running QueueManager, it cannot continue to run,
  # otherwise it has to be the same pid as stored in the database
  # for it to be allowed to continue
  def self.can_run?(pid:)
    return false if !active_qm
    if active_qm.pid == pid
      return true
    end
    return false
  end

  # Start is called by QueueManager, which then sets started_at and its pid
  def self.start(pid:)
    return nil if !can_start?
    QueueManagerPid.create(pid: pid, started_at: Time.now, version_string: VERSION_DATA["version"])
  end

  # Active means that the QueueManager is running AND actively running processes
  # Running means that the QueueManager is running, but it may be in an abort state
  # that has yet to finish, and will therefor not continue to run new processes
  def self.active_qm
    QueueManagerPid.where(aborted_at: nil).where(finished_at: nil).order(:started_at).first
  end
  
  # Fetch one QueueManagerPid object for the running one, and invalidate all others if multiple.
  # If none is found, return nil
  def self.running_qm
    qms = QueueManagerPid.where(finished_at: nil).order(:started_at)
    
    if qms.blank?
      return nil
    end
    
    real_qm = nil
    qms.each do |qm| 
      if !real_qm && qm.is_really_running?
        real_qm = qm
      elsif real_qm && qm.is_really_running?
        real_qm.abort
        real_qm = qm
      else
        qm.cleanup_old_pid
      end
    end
    
    return real_qm
  end


  # Actually run QueueManager via rake task. This process will then immediately do the startup
  # procedure with its own pid to fill the database with proper data.
  def self.execute_queue_manager!
    system("(cd \"#{Rails.root}\"; RAILS_ENV=\"#{Rails.env}\" nohup bundle exec rake queue_manager:run >> #{LOGFILE} 2>&1) &")
  end

  def is_really_running?
    if Rails.env == "test"
      running_process = running_process_mock
    else
      running_process = `ps -p #{self.pid} -o comm=`
    end

    # If process is a ruby script, consider it to be running
    if running_process.strip.start_with? "ruby"
      return true
    end
    return false
  end
  
  def cleanup_old_pid
    abort(skip_save: true)
    finish
  end
  
  def abort(skip_save: false)
    self.aborted_at = Time.now
    save if !skip_save
  end
  
  def finish
    self.finished_at = Time.now
    save
  end
  
  
end

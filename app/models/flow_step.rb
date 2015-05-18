class FlowStep < ActiveRecord::Base
  belongs_to :job

  validates :step, uniqueness: {scope: [:job_id, :aborted_at]}
  validates :step, numericality: { only_integer: true }

  validates :process, presence: true
  validate :process_in_list
  validate :validate_params

  # Returns true if step has not been aborted
  def is_active?
    aborted_at.nil?
  end

  # Returns error if mandatory params are missing
  def validate_params
    if process_object && process_object["required_params"]
      process_object["required_params"].each do |param|
        if !params_hash.has_key?(param)
          errors.add(:params, "Missing mandatory param #{param}")
        end
      end
    end
  end

  # Check if status is in list of configured sources
  def process_in_list
    if !APP_CONFIG["processes"].map { |x| x["code"] }.include?(process)
      errors.add(:process, "#{process} not included in list of valid statuses")
    end
  end

  def process_object
    @process_object ||= APP_CONFIG["processes"].find { |x| x["code"] == process}
  end

  def params_hash
    # Returns all params as a hash
    return {} if params.blank? || params == "null"
    @params_hash ||= JSON.parse(params)
  end

  # Returns true if step is the last one of the flow
  def finish_step?
    return !goto_true && !goto_false
  end

  # Returns true if step is the first one of the flow
  def start_step?
    params_hash["start"]
  end

  # Returns true if step is waiting to be entered
  def waiting?
    entered_at.nil?
  end

  # Returns true if step is entered
  def entered?
    entered_at.presence
  end

   # Returns true if step is next in line to be started
   def pending?
    entered_at.presence && started_at.nil?
  end

  # Returns true if step is currently running
  def running?
    started_at.presence? && finished_at.nil?
  end

  # Returns true if step is finished
  def finished?
    finished_at.presence?
  end

  def state
    process_object["state"]
  end

  def enter!
    self.entered_at = DateTime.now
    self.save!
    job.update_attribute('current_flow_step', step)
    job.create_log_entry("FLOW_STEP", "entered")
  end

  def start!
    self.started_at = DateTime.now
    self.save!
    job.create_log_entry("FLOW_STEP", "started")
  end

  def finish!
    self.finished_at = DateTime.now
    self.save!
    job.create_log_entry("FLOW_STEP", "finished")
    if next_step
      next_step.enter!
    end
  end

  # Returns next step if exists and not already entered
  def next_step
    if goto_true.present?
      fs = FlowStep.job_flow_step(job_id: job_id, flow_step: goto_true)
      if fs.entered?
        job.update_attibutes(quarantined: true, message: "Broken flow, step already entered #{fs.step}, called from #{self.step}")
        return nil
      else
        return fs
      end
    end
    nil
  end

  def abort!
    self.aborted_at = DateTime.now
    self.save!
  end

  def self.job_flow_step(job_id:, flow_step:)
    FlowStep.where(job_id: job_id, step: flow_step, aborted_at: nil).first
  end


end

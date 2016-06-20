class FlowStep < ActiveRecord::Base
  belongs_to :job

  validates :step, uniqueness: {scope: [:job_id, :aborted_at]}
  validates :step, numericality: { only_integer: true }

  validates :process, presence: true
  validate :process_in_list
  validate :validate_params

  def as_json(opts={})
    super.merge({
      params: params_hash
    })
  end

  # Short string representation of flow step
  def info_string
    "#{step}: #{process}"
  end

  # Returns true if step has not been aborted
  def is_active?
    aborted_at.nil?
  end

  # Returns error if mandatory params are missing
  def validate_params
    if process_object && process_object["required_params"]
      process_object["required_params"].each do |param|
        if !params_hash.has_key?(param)
          errors.add(:params, "#{step} Missing mandatory param #{param}")
        end
      end
    end
  end

  # Check if status is in list of configured sources
  def process_in_list
    if !SYSTEM_DATA["processes"].map { |x| x["code"] }.include?(process)
      errors.add(:process, "#{process} not included in list of valid statuses")
    end
  end

  def process_object
    @process_object ||= SYSTEM_DATA["processes"].find { |x| x["code"] == process}
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
    entered_at.present? && started_at.nil?
  end

  # Returns true if step is currently running
  def running?
    started_at.present? && finished_at.nil?
  end

  # Returns true if step is started
  def started?
    started_at.present?
  end

  # Returns true if step is finished
  def finished?
    finished_at.present?
  end

  def state
    process_object["state"]
  end

  # Returns flow step object referenced by goto_true
  def goto_true_step
    if goto_true
      return FlowStep.job_flow_step(job_id: self.job_id, flow_step: self.goto_true)
    end
    nil
  end

  # Returns flow step object referenced by goto_false
  def goto_false_step
    if goto_false
      return FlowStep.job_flow_step(job_id: self.job_id, flow_step: self.goto_false)
    end
    nil
  end

  # Returns true if step_nr occurs before given step
  def is_before?(step_nr)
    if goto_true == step_nr
      return true
    elsif goto_false == step_nr
      return true
    elsif goto_true_step && goto_true_step.is_before?(step_nr)
      return true
    elsif goto_false_step && goto_false_step.is_before?(step_nr)
      return true
    else
      return false
    end
  end

  # Returns true if step_nr occurs after given step
  def is_after?(step_nr)
    return !is_before?(step_nr) && !is_equal?(step_nr)
  end

  # Returns true if current step has given step_nr
  def is_equal?(step_nr)
    return step_nr == self.step
  end

  def enter!
    return true if entered?
    self.entered_at = DateTime.now
    self.save!
    job.nolog = true
    job.set_current_flow_step(self)
    job.update_attribute('state', main_state)
  end

  def start!(username: nil)
    return true if started?
    self.started_at = DateTime.now
    self.save!
    job.set_current_flow_step(self)
    if username
      job.created_by = username
    end
    job.create_log_entry("STARTED", self.description)
    job.update_attribute('state', main_state)
  end

  def finish!(username: nil)
    return true if finished?
    self.finished_at = DateTime.now
    self.save!
    if username
      job.created_by = username
    end
    job.create_log_entry("FINISHED", self.description)
    job.update_attribute('state', main_state)
    if next_step
      next_step.job = job
      next_step.enter!
    end
  end

  def abort!
    self.aborted_at = DateTime.now
    self.save!
  end

  # Returns main_state based on process type and location in flow
  def main_state
    if start_step?
      return "START"
    elsif finish_step? && finished?
      return "FINISH"
    elsif state == "ACTION" && !params_hash["manual"]
      return "PROCESS"
    elsif state == "WAITFOR"
      return "PROCESS"
    else
      return state
    end
  end

  # Returns next step if exists and not already entered
  def next_step
    if goto_true.present?
      fs = FlowStep.job_flow_step(job_id: job_id, flow_step: goto_true)
      if fs.entered?
        job.quarantine!(msg: "Broken flow, step already entered #{fs.step}, called from #{self.step}")
        return nil
      else
        return fs
      end
    end
    nil
  end

  def self.job_flow_step(job_id:, flow_step:)
    FlowStep.where(job_id: job_id, step: flow_step, aborted_at: nil).first
  end

  def parsed_params
    hash = params_hash
    hash.each do |key, value|
      if (value.kind_of? String) && (key != "format")
        hash[key] = substitute_parameters(value)
      else
        hash[key] = value
      end
    end
    return hash
  end

  def substitute_parameters(string)
    string % {job_id: job.id, page_count: job.page_count || '-1', package_name: job.package_name}
  end


end

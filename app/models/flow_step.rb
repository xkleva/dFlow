class FlowStep < ActiveRecord::Base
  default_scope {where( :aborted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  belongs_to :job
  belongs_to :flow

  validates :step, uniqueness: {scope: [:job_id, :aborted_at]}
  validates :step, numericality: { only_integer: true, allow_nil: true}, presence: true

  validate :step_differs_from_goto
  validates :process, presence: true
  validate :process_in_list
  validate :validate_params
  validate :validate_variables
  validates :description, presence: true
  validates :goto_true, numericality: { only_integer: true, allow_nil: true}, presence: true, unless: :is_last_step
  validates :goto_true, absence: true, if: :is_last_step
  
  attr_accessor :flow_parameters_hash

  def step_differs_from_goto
    if self.step == self.goto_true
      errors.add(:steps, "goto_true can't point to itself")
    end
  end

  def is_last_step
    params_hash['end'] == true
  end

  def is_first_step
    params_hash['start'] == true
  end

  # List of steps in queue for automated run.
  # Optionally limited by state
  def self.queued_steps(process_states: ['PROCESS', 'WAITFOR'])
    if process_states.kind_of?(String)
      process_states = [process_states]
    end
    automated_processes = SYSTEM_DATA['processes'].select do |x|
      process_states.include?(x['state'])
    end.map do |x| 
      x['code']
    end
    
    job_ids = Job.where(quarantined: false, deleted_at: nil).where.not(state: "FINISH").select(:id)
    return FlowStep.where.not(entered_at: nil).where(finished_at: nil, aborted_at: nil).where(job_id: job_ids).where('process in (?)', automated_processes).order(:started_at, updated_at: :asc)
  end

  def self.new_from_json(json:, job_id: nil, flow:)
    json["flow_id"] = flow.id
    json["job_id"] = job_id
    json["params"] = json["params"].to_json
    return FlowStep.new(json)
  end

  def as_json(opts={})
    super.merge({
      params: params_hash,
      parsed_params: parsed_params,
      state: process_object['state']
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
          errors.add(:params, "Step: #{step} - Missing mandatory param #{param}")
        end
      end
    end
  end

  # Check if status is in list of configured sources
  def process_in_list
    if !SYSTEM_DATA["processes"].map { |x| x["code"] }.include?(process)
      errors.add(:process, "Step: #{step} - #{process} not included in list of valid statuses")
    end
  end

  def process_object
    @process_object ||= (SYSTEM_DATA["processes"].find { |x| x["code"] == process}) || {}
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
    return flow.flow_step_is_before?(current_step:step, other_step:step_nr)
  end

  # Returns true if step_nr occurs after given step
  def is_after?(step_nr)
    return !flow.flow_step_is_before?(current_step:step, other_step:step_nr)
  end

  # Returns true if current step has given step_nr
  def is_equal?(step_nr)
    return step_nr == self.step
  end

  def enter!(username: nil)
    return true if entered?
    job.set_current_flow_step(self)
    # Skip step if conditions are not met
    if !condition_met?
      self.finished_at = DateTime.now
      self.save!(validate: false)
      if username
        job.created_by = username
      end
      job.update_attribute('state', main_state)
      job.create_log_entry("SKIPPED", self.description + " Condition not met: #{condition}")
      if next_step
        next_step.job = job
        next_step.enter!
      end
    else
      self.entered_at = DateTime.now
      self.save!(validate: false)
      return false if !parsed_params(quarantine_if_empty: true)
      job.nolog = true
      job.update_attribute('state', main_state)
    end
  end

  def start!(username: nil)
    return true if started?
    self.started_at = DateTime.now
    self.save!(validate: false)
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
    self.save!(validate: false)
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
    self.save!(validate: false)
  end

  # Forces att timestamps to be set for given flow_step
  def force_finish!
    if !entered?
      self.entered_at = DateTime.now
    end
    if !started?
      self.started_at = DateTime.now
    end
    if !finished?
      self.finished_at = DateTime.now
    end

    self.save!(validate: false)
  end

  # resets all timestams for given flow_step
  def reset!
    self.entered_at = nil
    self.started_at = nil
    self.finished_at = nil
    self.status = ""

    self.save!(validate: false)
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

  def parsed_params(quarantine_if_empty: false)
    hash = params_hash
    new_hash = {}
    hash.each do |key, value|
      if (value.kind_of? String) && (key != "format")
        begin
        new_hash[key] = Job.substitute_parameters(string: value,
                                                  require_value: quarantine_if_empty,
                                                  job_variables: job.variables,
                                                  flow_variables: job.flow_parameters_hash)
        rescue KeyError => e
          job.quarantine!(msg: "A parameter in #{key} is not set: #{e}")
          return nil
        end
      elsif key == "format"
        new_hash['format_params'] = value
      else
        new_hash[key] = value
      end
    end
    return new_hash
  end

  def params_validation
    hash = params_hash
    new_hash = {}
    hash.each do |key, value|
      if (value.kind_of? String) && (key != "format")
        begin
          new_hash[key] = Job.substitute_parameters(string: value, 
                                                    job_variables: Job.validatable_hash,
                                                    flow_variables: flow_parameters_hash)
        end
      elsif key == "format"
        new_hash['format_params'] = value
      else
        new_hash[key] = value
      end
    end
    return new_hash
  end
  
  def validate_variables
    begin
      self.params_validation
    rescue KeyError => e
      errors.add(:params, "Step: #{step} - Undefined variable #{e}")
    end
  end


  # Check if conditions for running flow step are met. If none exist, return true.
  def condition_met?
    if condition.present?
      parsed_condition = Job.substitute_parameters(string: condition,
                                                   job_variables: job.variables,
                                                   flow_variables: job.flow_parameters_hash)
      return eval(parsed_condition)
    end
    return true
  end


end

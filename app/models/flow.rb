class Flow
  #attr_accessor :name
  attr_accessor :flow_steps
  #attr_accessor :flow_steps_hash
  attr_accessor :errors

  def self.all
    flows = []
    workflows = APP_CONFIG["workflows"]
    workflows.each do |wf|
      flows << Flow.new(wf)
    end
    return flows
  end

  def self.find(flow_name)
    hash = APP_CONFIG["workflows"].find{|x| x["name"] == flow_name}
    if !hash
      raise StandardError, "No such workflow #{flow_name}"
    end
    Flow.new(hash)
  end

  def as_json(options={})
    {
     name: @name,
     flow_steps: @workflow_hash['steps'],
     parameters: @workflow_hash['parameters']
    }
  end

  def initialize(workflow_hash, job_id=0)
    @workflow_hash = workflow_hash
    @name = workflow_hash["name"]
    @flow_steps_hash = workflow_hash["steps"]
    @parameters = workflow_hash["parameters"] || []
  end

  def valid?
    @errors ||= []
    validate
    @errors.blank?
  end

  def parameter_hash
    hash = {}
    @parameters.each do |parameter|
      hash[parameter['name']] = nil
    end
    return hash
  end

  # Create flow step objects for job
  def generate_flow_steps(job_id, steps_list = [])
    @flow_steps = []
    @workflow_hash["steps"].each do |flow_step|
      # Skip step if step_list has values and current step is not part of it
      if steps_list.present? && !steps_list.include?(flow_step["step"])
        next
      end
      params = flow_step.dup
      params["job_id"] = job_id
      params["params"] = params["params"].to_json
      @flow_steps << FlowStep.new(params)
    end
  end

  def validate
    # Validate each step independently
    if !@flow_steps
      generate_flow_steps(0)
    end
    @flow_steps.each do |fs|
      if !fs.valid?
        @errors << fs.errors
      end
    end

    step_nrs = @flow_steps_hash.map{|x| x["step"]}
    goto_true_nrs = @flow_steps_hash.map{|x| x["goto_true"]}.compact
    goto_false_nrs = @flow_steps_hash.map{|x| x["goto_false"]}.compact
    
    # Validate each step nr
    if step_nrs.count != step_nrs.uniq.count
      @errors << {step: "Duplicated step nrs exist!"}
    end

    # Validate existence of step nr from references
    if (goto_true_nrs - step_nrs).present?
      @errors << {step: "Given goto_true step does not exist! #{(goto_true_nrs - step_nrs).inspect}"}
    end

    if (goto_false_nrs - step_nrs).present?
      @errors << {step: "Given goto_false step does not exist! #{(goto_false_nrs - step_nrs).inspect}"}
    end

    # Check for circular references
    @flow_steps_hash.each do |flow_step|
      if flow_step_is_before?(flow_step, flow_step["step"])
        @errors << {step: "Circular reference exists for step: #{flow_step["step"]}"}
      end
    end

  end

  # Returns true if given step_nr occurs anywhere below flow_step
  def flow_step_is_before?(flow_step, step_nr)
    return false if flow_step.nil? || step_nr.nil?
    if flow_step["goto_true"] == step_nr
      return true
    elsif flow_step["goto_false"] == step_nr
      return true
    elsif flow_step["goto_true"] && flow_step_is_before?(find_flow_step(flow_step["goto_true"]),step_nr)
      return true
    elsif flow_step["goto_false"] && flow_step_is_before?(find_flow_step(flow_step["goto_false"]),step_nr)
      return true
    else
      return false
    end
  end

  # Returns a flow_step hash from total array
  def find_flow_step(step_nr)
    return @flow_steps_hash.find{|x| x["step"] == step_nr}
  end

  # Returns the lowest step nr witin flow
  def first_step_nr
    first_step["step"]
  end

  # Returns start step
  def first_step
    @flow_steps_hash.find{|x| x["params"]["start"]}
  end

  # Returns final step
  def last_step
    @flow_steps_hash.find{|x| x["goto_true"].nil? && x["goto_false"].nil?}
  end

  def step_nr_valid?(step_nr)
    @flow_steps_hash.map{|x| x["step"]}.include?(step_nr)
  end

  # Creates new flow_steps, sets earlier as done and aborts old ones.
  def create_flow_steps(job:, step_nr:)
  end

  # Create flow steps for job id
  def apply_flow(job:, step_nr: nil, new_flow: false)
    if !job
      raise StandardError, "Job missing"
    end
    # If no step nr is assigned, use the lowest one
    if !step_nr
      step_nr = first_step_nr
    else
      if !step_nr_valid?(step_nr)
        raise StandardError, "Invalid step nr #{step_nr}"
      end
    end

    # List of step_nrs to be generated
    generate_steps_list = []

    job.flow_steps.each do |flow_step|
      flow_step.job = job

      # Abort if new flow is to be applied
      if new_flow
        flow_step.abort!
        next
      end

      # Abort all existing flow_steps after and including given step_nr
      if flow_step.is_after?(step_nr) || flow_step.is_equal?(step_nr)
        flow_step.abort!
        generate_steps_list << flow_step.step
      end

      # Finish all existing flow_steps before given step_nr
      if flow_step.is_before?(step_nr)
        if !flow_step.entered?
          flow_step.update_attribute('entered_at', DateTime.now)
        end
        if !flow_step.started?
          flow_step.update_attribute('started_at', DateTime.now)
        end
        if !flow_step.finished?
          flow_step.update_attribute('finished_at', DateTime.now)
        end
      end
    end

    # Generate new flow steps
    generate_flow_steps(job.id, generate_steps_list)

    Job.transaction do
      FlowStep.transaction do
        flow_steps.each do |flow_step|
          flow_step.save!
          if flow_step.step == step_nr
            flow_step.job = job
            flow_step.enter!
          end
          if flow_step_is_before?(find_flow_step(flow_step.step), step_nr)
            flow_step.update_attribute('entered_at', DateTime.now)
            flow_step.update_attribute('started_at', DateTime.now)
            flow_step.update_attribute('finished_at', DateTime.now)
          end
        end
      end
    end
  end

end

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

  def initialize(workflow_hash, job_id=0)
    @workflow_hash = workflow_hash
    @name = workflow_hash["name"]
    @flow_steps_hash = workflow_hash["steps"]
  end

  def valid?
    @errors ||= []
    validate
    @errors.blank?
  end

  def generate_flow_steps(job_id)
    @flow_steps = []
    @workflow_hash["steps"].each do |flow_step|
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
      @errors << {step: "Duplicated step nrs exists!"}
    end

    # Validate existence of step nr from references
    if (goto_true_nrs - step_nrs).present?
      @errors << {step: "Given goto step does not exist! #{(goto_true_nrs - step_nrs).inspect}"}
    end

    if (goto_false_nrs - step_nrs).present?
      @errors << {step: "Given goto step does not exist! #{(goto_false_nrs - step_nrs).inspect}"}
    end
  end

  # Returns the lowest step nr witin flow
  def first_step_nr
    @flow_steps_hash.map{|x| x["step"]}.min
  end

  def step_nr_valid?(step_nr)
    @flow_steps_hash.map{|x| x["step"]}.include?(step_nr)
  end

  # Create flow steps for job id
  def apply_flow(job, step_nr=nil)

    if !job
      raise StandardError, "Job missing"
    end

    generate_flow_steps(job.id)

    # If no step nr is assigned, use the lowest one
    if !step_nr
      step_nr = first_step_nr
    else
      if !step_nr_valid?(step_nr)
        raise StandardError, "Invalid step nr #{step_nr}"
      end
    end

    Job.transaction do
      FlowStep.transaction do
        flow_steps.each do |flow_step|
          flow_step.save!
        end
        job.update_attribute('current_flow_step', step_nr)
      end
    end
  end

end
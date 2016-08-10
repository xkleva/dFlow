class Flow < ActiveRecord::Base 
  default_scope {where( :deleted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow

  validate :validate_json
  validate :validate_steps

  def as_json(options={})
    {
     id: id,
     name: name,
     description: description,
     flow_steps: {flow_steps: steps_array},
     parameters: {parameters: parameters_array},
     folder_paths: {folder_paths: folder_paths_array}
    }
  end

  def validate_json
    begin 
      JSON.parse(self.steps)
    rescue JSON::ParserError => e
      errors.add(:steps, "JSON ParseError: #{e}")
    end
    begin 
      JSON.parse(self.parameters)
    rescue JSON::ParserError => e
      errors.add(:parameters, "JSON ParseError: #{e}")
    end
    begin 
      JSON.parse(self.folder_paths)
    rescue JSON::ParserError => e
      errors.add(:folder_paths, "JSON ParseError: #{e}")
    end
  end

  def steps_array
    return [] if steps.blank? || parameters == "null"
    @steps_array ||= JSON.parse(steps)
  end

  def parameters_array
    return [] if parameters.blank? || parameters == "null"
    @parameters_array ||= JSON.parse(parameters)
  end

  def parameters_hash
    parameters_array.map{|param| {param['name'] => nil}}.reduce({}, :merge)
  end

  def folder_paths_array 
    return [] if folder_paths.blank? || folder_paths == "null"
    @folder_paths_array ||= JSON.parse(folder_paths)
  end

  # Create flow step objects for job
  def generate_flow_steps(job_id)
    @flow_steps = []
    steps_array.each do |flow_step|
      @flow_steps << FlowStep.new_from_json(json: flow_step, job_id: job_id, flow: self)
    end
  end

  def validate_steps
    # Validate each step independently
    if !@flow_steps
      generate_flow_steps(0)
    end
    @flow_steps.each do |fs|
      if !fs.valid?
        fs.errors.full_messages.each do |error_msg|
          errors.add(:steps, error_msg)
        end
      end
    end

    step_nrs = steps_array.map{|x| x["step"]}
    goto_true_nrs = steps_array.map{|x| x["goto_true"]}.compact

    # Validate that start step exists
    start_steps = @flow_steps.select{|fs| fs.is_first_step}
    if start_steps.count < 1
      errors.add(:steps, "No start step exist (add the param 'start': true to first step)")
    end
    if start_steps.count > 1
      errors.add(:steps, "Only one start step is allowed (remove param 'start': true from one of steps: #{start_steps.map{|fs| fs.step}.inspect})")
    end
    
    # Validate that end step exists
    end_steps = @flow_steps.select{|fs| fs.is_last_step}
    if end_steps.count < 1
      errors.add(:steps, "No end step exist (add the param 'end': true to last step)")
    end
    if end_steps.count > 1
      errors.add(:steps, "Only one end step is allowed (remove param 'end': true from one of steps: #{end_steps.map{|fs| fs.step}.inspect})")
    end

    # Validate each step nr uniqueness
    if step_nrs.count != step_nrs.uniq.count
      multiple_step_nrs = step_nrs.select{ |e| step_nrs.count(e) > 1 }.uniq
      errors.add(:steps, "Duplicated step nrs exist: #{multiple_step_nrs.inspect}")
    end

    # Validate each goto_true uniqueness
    if goto_true_nrs.count != goto_true_nrs.uniq.count
      multiple_goto_true_nrs = goto_true_nrs.select{ |e| goto_true_nrs.count(e) > 1 }.uniq
      errors.add(:steps, "Duplicated goto_true nrs exist: #{multiple_goto_true_nrs.inspect}")
    end

    # Validate number of goto_true equals step nrs -1
    if step_nrs.count - goto_true_nrs.count != 1
      errors.add(:steps, "All steps not pointed to by goto")
    end

    # Validate existence of step nr from references
    if (goto_true_nrs - step_nrs).present?
      errors.add(:steps, "Given goto_true step does not exist: #{(goto_true_nrs - step_nrs).inspect}")
    end

    # Check for circular references
    steps_array.each do |flow_step|
      if flow_step_is_before?(flow_step, flow_step["step"])
        errors.add(:steps, "Circular reference exists for step: #{flow_step["step"]}")
      end
    end

   @flow_steps = nil

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
    return steps_array.find{|x| x["step"] == step_nr}
  end

  # Returns the lowest step nr witin flow
  def first_step_nr
    first_step["step"]
  end

  # Returns start step
  def first_step
    steps_array.find{|x| x["params"]["start"]}
  end

  # Returns final step
  def last_step
    steps_array.find{|x| x["goto_true"].nil? && x["goto_false"].nil?}
  end

  def step_nr_valid?(step_nr)
    steps_array.map{|x| x["step"]}.include?(step_nr)
  end

  # Create flow steps for job id
  def apply_flow(job:, step_nr: nil)
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

    job.flow_steps.each do |flow_step|
      flow_step.job = job

      # Abort old flow_steps
      flow_step.abort!
    end
    generate_flow_steps(job.id)
    Job.transaction do
      FlowStep.transaction do
        @flow_steps.each do |flow_step|
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

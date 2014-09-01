class Flow < ActiveRecord::Base
	belongs_to :flow_step, :foreign_key => :start_position, :primary_key => :id
	validates :start_position, presence: true
	#validate :flow_parameters_validity

	# Make sure given parameters are valid
	def flow_parameters_validity
		flow_parameters = JSON.parse(params_info)
		flow_parameters.each do |param|
			origin = FlowParameter.find_by_id(param[:id])
			return false if !origin
			if (param[:values]-origin.values).empty?
				next
			else
				return false
			end
		end
		true
	end

	# Returns an array with all flow step objects for flow
	def get_flow_steps
		flow_steps = []
		flow_step_ids = FlowStep.get_node_ids_from_startpoint(start_position)
		flow_steps = FlowStep.find(flow_step_ids)
		return flow_steps
	end



	# Define the objects JSON structure
	def as_json(opts)
		super.merge({
			:flow_steps => get_flow_steps
			})
	end

	# Updates flow steps
	def update_flow_steps(new_steps, new_start_position)
		if !validate_flow_steps(new_steps)
			return false
		end

		### Build the new FlowStep structure


		# Build structure
		built_steps = {}
		new_steps.each do |step|
			if built_steps.has_key?(step["id"])
				current_step = built_steps[step["id"]]
			else
				current_step = FlowStep.new(process_id: step["process_id"], condition_method: step["condition_method"], condition_operator: step["condition_operator"], condition_value: step["condition_value"], params: step["params"])
			end
			# Set goto_true and goto_false objects
			if step["goto_true"] != nil
				# If step exists, use it, otherwise create it
				if built_steps.has_key?(step["goto_true"])
					current_step.goto_true_step = built_steps[step["goto_true"]]
				else
					goto_step = new_steps.select {|x| x["id"] == step["goto_true"]}.first
					return false if !goto_step
					current_step.build_goto_true_step(process_id: goto_step["process_id"], condition_method: goto_step["condition_method"], condition_operator: goto_step["condition_operator"], condition_value: goto_step["condition_value"], params: goto_step["params"])
					built_steps[step["goto_true"]] = current_step.goto_true_step
				end
			end
			if step["goto_false"] != nil
				# If step exists, use it, otherwise create it
				if built_steps.has_key?(step["goto_false"])
					current_step.goto_false_step = built_steps[step["goto_false"]]
				else
					goto_step = new_steps.select {|x| x["id"] == step["goto_false"]}.first
					return false if !goto_step
					current_step.build_goto_false_step(process_id: goto_step["process_id"].to_i, condition_method: goto_step["condition_method"], condition_operator: goto_step["condition_operator"], condition_value: goto_step["condition_value"], params: goto_step["params"])
					built_steps[step["goto_false"]] = current_step.goto_false_step
				end
			end
			built_steps[step["id"]] = current_step
		end

		built_steps.each do |key,value|
			value.save
		end
		self.flow_step = built_steps[new_start_position]
		self.save
		return true
	end

	# Validates a hash of flow steps
	def validate_flow_steps(flow_steps)

		true
	end
	
end

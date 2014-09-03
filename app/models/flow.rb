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
		if !validate_flow_steps(new_steps, new_start_position)
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
	def validate_flow_steps(flow_steps, new_start_position)
		# Flow startpoint must exist
		start_step = flow_steps.select{|x| x["id"] == new_start_position.to_i}.first
		if !start_step
			errors.add(:start_position, "Start position doesn't exist")
			return false
		end
		# All steps must be connected to startpoint
		@start_id = start_step["id"]
		@flow_steps = flow_steps
		flow_steps.each do |step|
			if !connected_to_start?(step)
				errors.add(:start_position, "Flow step #{step["id"]} is not connected to start node")
				return false
			end
		end

		# There must be at least one endpoint (goto_true => nil && goto_false => nil)
		has_endpoint = false
		flow_steps.each do |step|
			if !step["goto_true"] && !step["goto_false"]
				has_endpoint = true
				break
			end
		end
		if !has_endpoint
			errors.add(:start_position, "End position doesn't exist")
			return false
		end

		true
	end

	# Returns true if step is connected to start node
	def connected_to_start?(step)
		continue = true
		current_step = step
		done_steps = []
		if (step["id"] == @start_id)
			return true
		end
		while (continue) do
			continue = false
			# Find steps which calls current step
			called_by = @flow_steps.select{|x| (x["goto_true"] == current_step["id"]) || (x["goto_false"] == current_step["id"])}
			called_by.each do |calling_step|
				# If called by start, return true
				if calling_step["id"] == @start_id
					return true
				end
				# If called by itself, move on
				if calling_step["id"] == step["id"]
					next
				end

				if !done_steps.include? calling_step["id"]
					current_step = calling_step
					done_steps << current_step["id"]
					continue = true
				end
			end
		end
		return false
	end
	
end

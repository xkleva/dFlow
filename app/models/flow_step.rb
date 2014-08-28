class FlowStep < ActiveRecord::Base

	# Returns the next step for a given job
	def next_step(job, success = nil)
		# If condition is set, evaluate it
		if !process_id && condition_method
			success = evaluate_condition(job)
		end

		if success == true
			return get_goto_true_step
		elsif success == false
			return get_goto_false_step
		end
	end

	# Evaluates condition if applicable and returns true/false
	def evaluate_condition(job)
		return false if !condition_method || !condition_operator || !condition_value
		# If method is integer, lookup parameter
		if condition_method.is_i?
			job_value = job.get_flow_param_key(condition_method)
			return false if !job_value
		else
			# Call job method
			job_value = job.send job_value.to_sym
		end
		# Different operations depending on operator
		case condition_operator
		when "eq"
			return condition_value.eql? job_value.to_s
		end
		return false
	end

	# Returns next step for condition == true
	def get_goto_true_step
		return nil if !goto_true
		if goto_true.is_i?
			step_id = goto_true.to_i
			return FlowStep.find_by_id(step_id)
		end
	end

	# Returns next step for condition == false
	def get_goto_false_step
		return nil if !goto_false
		if goto_false.is_i?
			step_id = goto_false.to_i
			return FlowStep.find_by_id(step_id)
		end
	end

	# Step is final if no goto exists
	def is_final_step?
		return !goto_true && !goto_true
	end

	def has_goto_false?
		if goto_false && goto_false.is_i?
			return true
		else 
			return false
		end
	end

	def has_goto_true?
		if goto_true && goto_true.is_i?
			return true
		else 
			return false
		end
	end

	def self.get_node_ids_from_startpoint(start_point)
		node_ids = []
		start = FlowStep.find_by_id(start_point)
		if !start
			return node_ids
		end

		current_step = start
		continue = true
		i = 0

		# Iterate through all steps until end
		while continue && i < 10000 do
			i += 1
			node_ids << current_step.id

			# If final step, break loop
			if current_step.is_final_step?
				continue = false
				next
			end

			# If goto_false exists, add all node ids from false node
			if current_step.has_goto_false?
				node_ids << get_node_ids_from_startpoint(current_step.goto_false.to_i)
			end
			
			if current_step.has_goto_true?
				current_step = FlowStep.find_by_id(current_step.goto_true.to_i)
			end
		end

		return node_ids.uniq
	end
end

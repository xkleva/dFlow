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
end

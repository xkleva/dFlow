class FlowStep < ActiveRecord::Base
	belongs_to :goto_true_step, class_name: "FlowStep", foreign_key: "goto_true"
	belongs_to :goto_false_step, class_name: "FlowStep", foreign_key: "goto_false"

	# Returns the next step for a given job
	def next_step(job, success = nil)
		# If condition is set, evaluate it
		if !process_id && condition_method
			success = evaluate_condition(job)
		end

		if success == true
			return goto_true_step
		elsif success == false
			return goto_false_step
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

	# Step is final if no goto exists
	def is_final_step?
		return !goto_true_step && !goto_false_step
	end

	def has_goto_false?
		if goto_false_step
			return true
		end
	end

	def has_goto_true?
		if goto_true_step
			return true
		end
	end

	# Returns all flow_steps from start_point to end
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

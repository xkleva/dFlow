class FlowStep < ActiveRecord::Base
	validates :process_id, presence: true

	# Returns the next step for a given job
	def next_step(job, success)
		# If no condition is asked for
		if process_id > 0
			if success
				return get_goto_true_step
			elsif !success
				return get_goto_false_step
			end
		end
		# TODO add logic for IF statements
		return nil
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

# Contains methods for process management
class ProcessModel
	attr_accessor :id,:allowed_processes,:code

	def initialize(process_hash)
		@id = process_hash[:id]
		@allowed_processes = process_hash[:allowed_processes]
		@code = process_hash[:code]
	end

	# Returns config hash for given process_id
	def self.find_on_code(process_code)
		process = Rails.configuration.process_list.select{|x| x[:code] == process_code}.first
		return nil if !process
		return ProcessModel.new(process)
	end
	
	# Returns all entries for given process and state
	def entries(state)
		Entry.where(state: state).joins(:flow_step).where(flow_steps: {process_id: id})
	end

	# Returns a job which is pendning for current process_id
	def first_pending_job
		entry = entries("PENDING").oldest
		return nil if entry.nil?
		Job.find(entry.job_id)
	end

	# Updates the state for given job
	def update_state_for_job(job_id, state)
		job = Job.find(job_id)
		return false if job.nil?
		
		workflow_step = FlowStep.find(job.current_processing_entry.workflow_step_id)
		return false if workflow_step.nil?

		return false if workflow_step.process_id != process_id

		pe = Entry.new(job_id: job.id, flow_step_id: workflow_step.id, state: state)
		return pe.save!
	end

	# returns true if process can be started based on running and allowed concurrent processes
	def startable?
		processing = 0
		# Check if the allowed amount of processes are already running
		processing = entries("STARTED").size
		if allowed_processes && processing >= allowed_processes
			return false
		end
		return true
	end
end
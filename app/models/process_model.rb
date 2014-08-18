# Contains methods for process management
class ProcessModel
	  # Required dependency for ActiveModel::Errors
	  extend ActiveModel::Naming
	  attr_accessor :id,:allowed_processes,:code
	  attr_reader   :errors

	  def initialize(process_hash)
	  	@id = process_hash[:id]
	  	@allowed_processes = process_hash[:allowed_processes]
	  	@code = process_hash[:code]
	  	@errors = ActiveModel::Errors.new(self)
	  end

	  def validate!
	  	errors.add(:name, "cannot be nil") if name == nil
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
		Job.find_by_id(entry.job_id)
	end

	# Updates the state for given job
	def update_state_for_job(job_id, state)

		job = Job.find_by_id(job_id)
		if !job
			errors.add(:job_id, "could_not_find_job")
			return false
		end
		
		flow_step = FlowStep.find_by_id(job.current_entry.flow_step_id)
		if !flow_step
			errors.add(:flow_step_id, "could_not_find_flow_step")
			return false
		end

		if flow_step.process_id != id
			errors.add(:process_id, "process_ids_do_not_match")
			return false
		end

		# create new entry for state
		return false if !new_entry(job.id, flow_step.id, state)

		# If job is done, ask for next step and create entry
		if state == "DONE"
			next_step = flow_step.next_step(job, true)
			if !next_step # If nil create JOB_END entry
				return false if !new_entry(job.id, nil, "JOB_END")
			else
				return false if !new_entry(job.id, next_step.id, "PENDING")
			end
		end

		return true
	end

	# cretaes an entry for given parameters
	def new_entry(job_id, flow_step_id, state)
		entry = Entry.new(job_id: job_id, flow_step_id: flow_step_id, state: state)
		if !entry.save
			@errors = entry.errors
			return false
		end
		true
	end

	# Updates job progress field
	def update_progress_for_job(job_id, progress)
		begin
			job = Job.find(job_id)
			job.progress_state = progress.to_json
		rescue
			return false
		end

	end

	# Returns true if process can be started based on running and allowed concurrent processes
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
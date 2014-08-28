class Flow < ActiveRecord::Base
	belongs_to :flow_step, :foreign_key => :start_position, :primary_key => :id
	validates :start_position, presence: true
	validate :flow_parameters_validity

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
		flow_step_ids.each do |id|
			step = FlowStep.find_by_id(id)
			flow_steps << step
		end
		return flow_steps
	end


	# Define the objects JSON structure
	def as_json(opts)
		super.merge({
			:flow_steps => get_flow_steps
			})
	end

	
end

class Flow < ActiveRecord::Base
	belongs_to :flow_step, :foreign_key => :start_position, :primary_key => :id
	validates :start_position, presence: true
	validate :flow_parameters_validity

	# make sure given parameters are valid
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
end

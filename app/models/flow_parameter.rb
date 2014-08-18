class FlowParameter

	def self.find_by_id(id)
		parameter = Rails.configuration.flow_parameters.select{|x| x[:id] == id}.first
		return nil if !parameter
		return FlowParameter.new(parameter)
	end

	def initialize(hash)
		@id = hash[:id]
		@code = hash[:code]
		@type = hash[:type]
		@values = hash[:values]
		@dependency = hash[:dependency]
	end

	# Returns true if dependency exists
	def has_dependency?
		return @dependency && !@dependency.empty?
	end

	# Returns true if all elements of hash are contained within object
	def contains(hash)
		(hash[:values]-@values).empty?
	end
end
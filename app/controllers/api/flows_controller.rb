
class Api::FlowsController < Api::ApiController
	before_filter :check_key

	# Returns a flow as json
	def get_flow
		flow_id = params[:flow_id]

		flow = Flow.find_by_id(flow_id)
		# If flow doesn't exist, return error message
		if !flow
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find a flow with id #{flow_id}")
			render json: @response
			return 
		end

		@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		@response[:data] = flow

		render json: @response
	end
end
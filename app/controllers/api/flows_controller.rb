
class Api::FlowsController < Api::ApiController
	before_filter :check_key
	before_filter :check_params

	# Returns a flow as json
	def get_flow
		@response[:data] = @flow
		@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")

		render json: @response
	end

	# Updates flow_steps for given flow and new start position
	def update_flow_steps
		new_steps = JSON.parse(params[:new_flow_steps])
		new_start_position = params[:new_start_position]
		
		if @flow.update_flow_steps(new_steps, new_start_position)
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		else
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find update flow step definition for flow #{params[:flow_id]}")
		end
		render json: @response
	end

	# Validate standardized parameters
	def check_params
		if params[:flow_id]
			flow_id = params[:flow_id]
			@flow = Flow.find_by_id(flow_id)
			# If flow doesn't exist, return error message
			if !@flow
				@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find a flow with id #{flow_id}")
				render json: @response
				return 
			end
		end
	end
end
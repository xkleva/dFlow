
class Api::ApiController < ApplicationController
	before_filter :check_key

	# Connection test method
	def check_connection
		render json: {status: ResponseData::ResponseStatus.new("SUCCESS")}
	end

	#Check if api_key is correct
	def check_key
		api_key = params[:api_key]
		if api_key == Rails.application.config.api_key 
			render json: {status: ResponseData::ResponseStatus.new("SUCCESS")}
		else
			render json: {status: ResponseData::ResponseStatus.new("FAIL").set_error("AUTH_ERROR", "Could not authorize API-key")}
		end
	end

end
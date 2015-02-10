
class Api::ApiController < ApplicationController
	before_filter :check_key

	# Connection test method
	def check_connection
		render json: 'SUCCESS', status: 200
	end

	private
	#Check if api_key is correct, otherwise return error
	def check_key
		@response ||= {}
		api_key = params[:api_key]
		if api_key != Rails.application.config.api_key
			error_msg(ErrorCodes::AUTH_ERROR, "Could not authorize API-key")
			render_json
		end
	end

	# Sorts a list of files based on filename
	def sort_files(files)
		files.sort_by { |x| x.basename.to_s[/^(\d+)\./,1].to_i }
	end

	# Renders the response object as json with proper request status
	def render_json
		# If successful, render with 200
		if @response[:error].nil?
			render json: @response, status: 200
		else
			render json: @response, status: ErrorCodes.const_get(@response[:error][:code])[:http_status]
		end
	end

 # Generates an error object from code, message and error list
	def error_msg(code=ErrorCodes::ERROR, msg="", error_list = nil)
		@response[:error] = {code: code[:code], msg: msg, errors: error_list}
	end
end

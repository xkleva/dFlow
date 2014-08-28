
class Api::ApiController < ApplicationController
	before_filter :check_key

	# Connection test method
	def check_connection
		render json: {status: ResponseData::ResponseStatus.new("SUCCESS")}
	end

	private 
	#Check if api_key is correct, otherwise return error
	def check_key
		@response ||= {}
		api_key = params[:api_key]
		if api_key != Rails.application.config.api_key
			render json: {status: ResponseData::ResponseStatus.new("FAIL").set_error("AUTH_ERROR", "Could not authorize API-key")}
		end
	end

	# Sorts a list of files based on filename
	def sort_files(files)
		files.sort_by { |x| x.basename.to_s[/^(\d+)\./,1].to_i }
	end

end
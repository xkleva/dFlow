
class Api::ConfigController < ApplicationController
	before_filter :check_key

	# Returns all config values not part of secret_keyes
	def config_values
		values = {}
		values[:msg] = "Success"
		values["copyright"] = DigFlow::Application.config.copyright
		values["mets_head"] = DigFlow::Application.config.mets_head
		values["mets_pagetypes"] = DigFlow::Application.config.mets_pagetypes
		values["mets_filegroups"] = DigFlow::Application.config.mets_filegroups
		values["base_processing_directory"] = DigFlow::Application.config.base_processing_directory
		values["base_scan_directory"] = DigFlow::Application.config.base_scan_directory
		values["base_store_directory"] = DigFlow::Application.config.base_store_directory
		values["base_ocr_directory"] = DigFlow::Application.config.base_ocr_directory

	render json: values

	end

	def check_key
		api_key = params[:api_key]
		if api_key != DigFlow::Application.config.api_key 
			render json: {msg: "Fail"}
		end
	end

end
class Api::ConfigController < Api::ApiController
	before_filter :check_key

	def index
	end

	# Returns a list of assignable roles on format {roles: ["ROLE1", "ROLE2", ...]}
	def role_list
		role_list = []

		# Select role name from config list of roles
		roles = Rails.application.config.user_roles.select{|role| !role[:unassignable]}
		roles.each {|role| role_list << role[:name]}

		# Set response
		if role_list.empty?
			error_msg(ErrorCodes::ERROR, "No User Roles are defined")
		else
			@response[:roles] = role_list
		end
		render_json

	rescue
		error_msg(ErrorCodes::ERROR, "Something went wrong")
		render_json
	end

end
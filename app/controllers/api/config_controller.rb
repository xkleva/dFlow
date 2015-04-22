class Api::ConfigController < Api::ApiController

  resource_description do
    short 'Config manager - Data specified in application configuration'
  end

  def index
  end

	# Returns a list of assignable roles on format {roles: ["ROLE1", "ROLE2", ...]}
  api!
  def role_list
    role_list = []
		# Select role name from config list of roles
    roles = APP_CONFIG["user_roles"].select{|role| !role["unassignable"]}
    roles.each {|role| role_list << {name: role["name"]}}

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

  # Returns a list of statuses
  api!
  def status_list
    status_list = []
    # Select role name from config list of roles
    statuses = APP_CONFIG["statuses"]
    statuses.each {|status| status_list << status["name"]}

    # Set response
    if status_list.empty?
      error_msg(ErrorCodes::ERROR, "No Statuses are defined")
    else
      @response[:statuss] = status_list
    end
    render_json

  rescue
    error_msg(ErrorCodes::ERROR, "Something went wrong")
    render_json
  end

end
class Api::ConfigController < Api::ApiController

  resource_description do
    short 'Config manager - Data specified in application configuration'
  end

  def index
  end

	# Returns a list of assignable roles on format {roles: ["ROLE1", "ROLE2", ...]}
  api :GET, '/config/roles', 'Returns a list of assignable roles for users'
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
  end

  # Returns a list of statuses
  api :GET, '/config/states', 'Returns a list of possible states for flow step processes'
  def state_list
    # Select role name from config list of roles
    states_list = APP_CONFIG["processes"].map{|x| x["state"]}.uniq
    states_list.unshift("START")
    states_list << "FINISH"

    # Set response
    if states_list.empty?
      error_msg(ErrorCodes::ERROR, "No States are defined")
    else
      @response[:states] = states_list.uniq
    end
    render_json
  end

end

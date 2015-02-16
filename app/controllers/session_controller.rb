class SessionController < ApplicationController

  # Create a session, with a newly generated access token
  def create
    user = User.find_by_username(params[:username])
    if user
      token = user.authenticate(params[:password])
      if token
        @response[:user] = user.as_json
        @response[:user][:role] = user.role_object
        @response[:access_token] = token
        @response[:token_type] = "bearer"
        render_json
        return
      end
    end
    error_msg(ErrorCodes::AUTH_ERROR, "Invalid credentials")
    render_json
  end
  
  def show
    @response = {}
    token = params[:id]
    token_object = AccessToken.find_by_token(token)
    if token_object && token_object.user.validate_token(token)
      @response[:user] = token_object.user.as_json
      @response[:user][:role] = token_object.user.role_object
      @response[:access_token] = token
      @response[:token_type] = "bearer"
    else
      error_msg(ErrorCodes::SESSION_ERROR, "Invalid session")
    end
    render_json
  end
end

require 'pp'
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_filter :setup

  # Setup global state for response
  def setup
    @response ||= {}
  end
  
  # Renders the response object as json with proper request status
  def render_json(status=200)
    # If successful, render given status
    if @response[:error].nil?
      render json: @response, status: status
    else
      # If not successful, render with status from ErrorCodes module
      render json: @response, status: ErrorCodes.const_get(@response[:error][:code])[:http_status]
    end
  end

  # Generates an error object from code, message and error list
  def error_msg(code=ErrorCodes::ERROR, msg="", error_list = nil)
    @response[:error] = {code: code[:code], msg: msg, errors: error_list}
  end

  private
  def validate_token
    token = get_token
    token.force_encoding('utf-8')
    token_object = AccessToken.find_by_token(token)
    if !token_object || !token_object.user.validate_token(token)
      headers['WWW-Authenticate'] = "Token"
      render json: {error: "Invalid token"}, status: 401
    end
  end

  def get_token
    return nil if !request || !request.headers
    token_response = request.headers['Authorization']
    return nil if !token_response
    token_response[/^Token (.*)/,1]
  end
end

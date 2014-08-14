class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  protect_from_forgery
  before_filter :record_history
  before_filter :setup
  after_filter :set_access_control_headers

  protected
  def setup
  	if request.env['HTTP_ACCEPT_LANGUAGE']
  		I18n.locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  	else
  		I18n.locale = 'en'
  	end
  	@current_user = User.find_by_id(cookies['user_id'])
  	if !@current_user || !@current_user.verify_session(session[:user_id],
  		session[:session_key],
  		cookies[:session_key])
	  	@current_user = nil
	  	if params[:api_key] == Rails.configuration.api_key && params[:id]
	  		@current_user = Job.find(params[:id]).user
	  		@current_user.api_login = true
	  	end
	  	if !@current_user
	  		@current_user = User.where(:role_id => Role.find_by_name("guest").id).first
	  	end
	  end
	  @global_quarantined_job_count = Job.where(:quarantined => true).count
	end

	def login_if_not_logged_in
		flash[:notice] = "common.must_be_logged_in"
		redirect_to :controller => 'users', :action => 'login', :return_path => request.fullpath if !@current_user.logged_in?
	end

	def login_if_not_admin
		flash[:notice] = "common.must_be_admin"
		redirect_to :controller => 'users', :action => 'login', :return_path => request.fullpath if !@current_user.is_admin?
	end

	def set_access_control_headers
		headers['Access-Control-Allow-Origin'] = '*'
		headers['Access-Control-Request-Method'] = '*'
	end

	protected
	def record_history
		session[:history] ||= []
		session[:history].push request.url unless session[:history][-1] == request.url
	    session[:history] = session[:history].last(10) # limit the size to 10
	    @back=session[:history][-2]
	end

	
end

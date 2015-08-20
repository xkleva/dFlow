class Api::PublicationLogController < ApplicationController

  before_filter -> { validate_rights 'manage_jobs' }, only: [:create]

  api!
  def index
    job_id = params[:job_id]

    if !job_id
      error_msg(ErrorCodes::REQUEST_ERROR,"Must give a valid job id")
      render_json
      return
    end

    publication_logs = PublicationLog.where(job_id: job_id)

    @response[:publication_logs] = publication_logs

    render_json

  end

  api!
  def create
    publication_log = PublicationLog.new(publication_log_params)
    
    # Set username if not given
    if !publication_log.username
      publication_log.username = @current_user.username
    end

    # Save object
    if publication_log.save
      @response[:publication_log] = publication_log
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not save publication log", publication_log.errors)
    end

    render_json
  end

  private

  def publication_log_params
    params.require(:publication_log).permit(:job_id, :publication_type, :username, :comment, :created_at)
  end

end

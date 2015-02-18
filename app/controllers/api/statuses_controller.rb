class Api::StatusesController < Api::ApiController
  before_filter :check_job

  # API endpoint to start digitizing
  def digitizing_begin
    new_status('waiting_for_digitizing', Status.find_by_name('digitizing'))
  end

  def digitizing_end
    new_status('digitizing', Status.find_by_name('digitizing').next_status)
  end

  def post_processing_begin
    ensure_status('post_processing')
  end

  def post_processing_end
    new_status('post_processing', Status.find_by_name('post_processing').next_status)
  end

  def post_processing_user_input_begin
    new_status('post_processing', Status.find_by_name('post_processing_user_input'))
  end

  def post_processing_user_input_end
    new_status('post_processing_user_input', Status.find_by_name('post_processing_user_input').next_status)
  end

  def quality_control_begin
    ensure_status('quality_control')
  end

  def quality_control_end
    new_status('quality_control', Status.find_by_name('quality_control').next_status)
  end

  def waiting_for_mets_control_begin
    ensure_status('waiting_for_mets_control')
  end

  def waiting_for_mets_control_end
    new_status('waiting_for_mets_control', Status.find_by_name('waiting_for_mets_control').next_status)
  end

  def mets_control_begin
    ensure_status('mets_control')
  end

  def mets_control_end
    new_status('mets_control', Status.find_by_name('mets_control').next_status)
  end


  private 

  def check_job
    @job = Job.find(params[:id])
    
    if @job.nil?
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find a job with id #{params[:id]}")
      render_json
      return
    end
  end

  # Changes status
  def new_status(from_status, to_status)

    return if !ensure_status('from_status')

    @job.created_by = @current_user.username
    @job.switch_status(to_status)

    if !job.save
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not save job", job.errors)
    end

    render_json
  end

  # Makes sure that job exists and is in correct status
  def ensure_status(status)

    if @job.status != status
      error_msg(ErrorCodes::QUEUE_ERROR, "Job is in wrong status: #{@job.status}")
      render_json
      return false
    end

    render_json
  end

end
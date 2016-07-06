class AssetsController < ApplicationController

  before_filter -> { validate_rights 'manage_jobs' }, only: [:job_pdf, :job_file]

  def work_order
    # Job print out asset
    job = Job.find_by_id(params[:asset_id])
    if !job
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find job with id: #{asset_id}")
      render_json
    else
      @response = {ok: "success"}
      respond_to do |format|
        format.json { render_json }
        format.pdf { send_data job.create_pdf, :filename => "#{job.id}.pdf", type: "application/pdf", disposition: "inline" }
      end
    end
  end

  def job_pdf
    # Job PDF asset
    job = Job.find_by_id(params[:asset_id])
    if !job
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find job with id: #{params[:asset_id]}")
      render_json
    elsif !job.has_pdf
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find PDF for job with id: #{params[:asset_id]}")
      render_json
    else
      job_pdf = FileAdapter.open_file(job.package_location, job.pdf_path)
      @response = {ok: "success"}
      
      respond_to do |format|
        format.json { render_json }
        format.pdf { send_data job_pdf.read, type: "application/pdf", disposition: "attachment" }
      end
    end
  end

  def job_file
    # Job PDF asset
    job = Job.find_by_id(params[:asset_id])
    if !job
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find job with id: #{params[:asset_id]}")
      render_json
    else
      file = FileAdapter.open_file(job.package_location, job.current_package_name + params[:file_dir] + params[:file_name])
      @response = {ok: "success"}
      
      send_data file.read, filename: params[:file_name], disposition: "inline"
    end
  end

end

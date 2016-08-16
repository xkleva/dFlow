class AssetsController < ApplicationController

  before_filter -> { validate_rights 'manage_jobs' }, except: [:work_order]

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

  def job_file
    # Job PDF asset
    job = Job.find_by_id(params[:asset_id])
    if !job
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find job with id: #{params[:asset_id]}")
      render_json
    else
      file = DfileApi.download_file(source_file: "#{job.package_location}/#{params[:file_dir]}/#{params[:file_name]}")
      @response = {ok: "success"}
      
      send_data file.read, filename: params[:file_name], disposition: "inline"
    end
  end

  def file
    file = DfileApi.download_file(source_file: params[:file_path])

    filename = Pathname.new(params[:file_path]).basename

    send_data file.read, filename: filename, disposition: "inline"
  end

  api!
  def thumbnail
    thumbnail = DfileApi.thumbnail(
      source_dir: params[:source_dir],
      source: params[:source],
      image: params[:image],
      filetype: params[:filetype],
      size: params[:size]
    )

    @response = {thumbnail: thumbnail}
    render_json
  end


end

class AssetsController < ApplicationController

  def show

    # Job print out asset
    if params[:asset_type] == 'work_order'
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

    # Job PDF asset
    if params[:asset_type] == 'job_pdf'
      job = Job.find_by_id(params[:asset_id])
      if !job
        error_msg(ErrorCodes::OBJECT_ERROR, "Could not find job with id: #{asset_id}")
        render_json
      else
        job_pdf = open(job.pdf_path)
        @response = {ok: "success"}
        
        respond_to do |format|
          format.json { render_json }
          format.pdf { send_file job_pdf, type: "application/pdf", disposition: "inline" }
        end
      end
    end
  end

end
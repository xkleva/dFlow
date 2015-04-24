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

        if job.done?
          location = APP_CONFIG["pdf_path_prefix_store"]
          id = sprintf("GUB%07d", job.id)
        else
          location = APP_CONFIG["pdf_path_prefix_packaging"]
          id = job.id.to_s
        end

        path = "#{location}/@@JOBID@@/pdf/@@JOBID@@.pdf"
        path = path.gsub("@@JOBID@@", id)

        job_pdf = open(path)
        @response = {ok: "success"}
        
        respond_to do |format|
          format.json { render_json }
          format.pdf { send_file job_pdf, type: "application/pdf", disposition: "inline" }
        end
      end
    end
  end

end
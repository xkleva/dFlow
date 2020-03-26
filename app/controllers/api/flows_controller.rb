class Api::FlowsController < Api::ApiController
  skip_before_filter :verify_authenticity_token, :only => [:index]
  before_filter -> { validate_rights 'manage_jobs' }, except: [:index]

  api!
  def index
    @response[:flows] = Flow.order('selectable desc, name asc').all.as_json({full: true})

    render_json
  end

  api!
  def show
    flow = Flow.find_by_id(params[:id])
    if flow
      @response[:flow] = flow
    else
      error_msg(ErrorCodes::REQUEST_ERROR, "Could not find flow with id '#{params[:id]}'")
    end

    render_json
  end

  api!
  def update
    flow_params = params[:flow]
    flow = Flow.find_by_id(params[:id])
    if !flow || !flow_params
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find flow with id '#{params[:id]}'")
    end

    flow_params[:steps] = flow_params[:flow_steps]['flow_steps'].present? ? flow_params[:flow_steps]['flow_steps'].to_json : '[]'
    flow_params[:parameters] = flow_params[:parameters]['parameters'].present? ? flow_params[:parameters]['parameters'].to_json : '[]'
    flow_params[:folder_paths] = flow_params[:folder_paths]['folder_paths'].present? ? flow_params[:folder_paths]['folder_paths'].to_json : '[]'

    if flow.update_attributes(permitted_params)
      @response[:flow] = flow
    else
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not save flow #{params[:id]}", flow.errors)
    end
    render_json
  end

  api!
  def create
    flow = Flow.new(permitted_create_params)

    if flow.save
      @response[:flow] = flow
    else
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not save flow #{params[:id]}", flow.errors)
    end
    render_json
  end

  api!
  def destroy
    flow = Flow.find_by_id(params[:id])
    if !flow
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find flow with id '#{params[:id]}'")
    end

    if flow.update_attribute('deleted_at', DateTime.now)
      @response[:flow] = flow
    else
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not delete flow #{params[:id]}")
    end
    render_json
  end

  private 
  def permitted_params
    params.require(:flow).permit(:name, :steps, :description, :folder_paths, :parameters, :selectable)
  end

  def permitted_create_params
    params.require(:flow).permit(:name)
  end
end

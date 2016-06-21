class Api::FlowsController < Api::ApiController
  skip_before_filter :verify_authenticity_token, :only => [:index]

  api!
  def index
    @response[:flows] = Flow.all

    render_json
  end
end

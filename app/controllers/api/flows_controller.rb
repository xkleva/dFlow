class Api::FlowsController < Api::ApiController
  skip_before_filter :verify_authenticity_token, :only => [:index]

  api!
  def index
    @response[:flows] = Flow.all.as_json({full: true})

    render_json
  end
end

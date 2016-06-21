class Api::FlowsController < Api::ApiController

  def index
    @response[:flows] = Flow.all

    render_json
  end
end

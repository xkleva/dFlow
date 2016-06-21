class Api::FlowsController < ApplicationController

  def index
    @response[:flows] = Flow.all

    render_json
  end
end

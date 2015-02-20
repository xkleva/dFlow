require 'rails_helper'

RSpec.configure do |c|
  c.include ModelHelper
end

describe Api::StatusesController do
  before :each do
    config_init
    @api_key = Rails.application.config.api_key
  end

  describe "digitizing_begin" do
    context "job has status waiting" do
      it "should return status 200" do
        get :digitizing_begin, id: 1, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
  end
end
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
    context "job has status digitizing" do
      it "should return status 422" do
        get :digitizing_begin, id: 3, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "digitizing_end" do
    context "job has status digitizing" do
      it "should return status 200" do
        get :digitizing_end, id: 3, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status waiting" do
      it "should return status 422" do
        get :digitizing_end, id: 1, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end
end
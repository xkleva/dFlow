require 'rails_helper'

RSpec.configure do |c|
  c.include ModelHelper
end

describe Api::StatusesController do
  before :each do
    config_init
    @api_key = APP_CONFIG["api_key"]
  end

  describe "digitizing_begin" do
    context "job has status waiting" do
      it "should return status 200" do
        job = create(:job, status: 'waiting_for_digitizing')
        get :digitizing_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :digitizing_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "digitizing_end" do
    context "job has status digitizing" do
      it "should return status 200" do
        job = create(:job, status: 'digitizing')
        get :digitizing_end, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status waiting" do
      it "should return status 422" do
        job = create(:job, status: 'waiting_for_digitizing')
        get :digitizing_end, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end
end
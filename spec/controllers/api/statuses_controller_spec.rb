require 'rails_helper'

describe Api::StatusesController do
  before :each do
    WebMock.disable_net_connect! 
    @api_key = APP_CONFIG["api_key_users"].first["api_key"]
  end
  after :each do
    WebMock.allow_net_connect!
  end

  # describe "digitizing_begin" do
  #   context "job has status waiting" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'waiting_for_digitizing')
  #       get :new, status: 'digitizing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status digitizing" do
  #     it "should return status 422" do
  #       job = create(:job, status: 'digitizing')
  #       get :new, status: 'digitizing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status post_processing" do
  #     it "should return status 422" do
  #       job = create(:job, status: 'post_processing')
  #       get :new, status: 'digitizing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 422
  #     end
  #   end
  #   context "job does not exist" do
  #     it "should return status 404" do
  #       get :new, status: 'digitizing', id: -1, api_key: @api_key
  #       expect(response.status).to eq 404
  #     end
  #   end
  # end

  # describe "digitizing_end" do
  #   context "job has status digitizing" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'digitizing')
  #       get :complete, status: 'digitizing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status waiting" do
  #     it "should return status 422" do
  #       job = create(:job, status: 'waiting_for_digitizing')
  #       get :complete, status: 'digitizing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 422
  #     end
  #   end
  # end

  # describe "post_processing_begin" do
  #   context "job has status post_processing" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'post_processing')
  #       get :new, status: 'post_processing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status digitizing" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'digitizing')
  #       get :new, status: 'post_processing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  # end

  # describe "post_processing_end" do
  #   context "job has status post_processing" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'post_processing')
  #       get :complete, status: 'post_processing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status digitizing" do
  #     it "should return status 422" do
  #       job = create(:job, status: 'digitizing')
  #       get :complete, status: 'post_processing', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 422
  #     end
  #   end
  # end

  # describe "post_processing_user_input_begin" do
  #   context "job has status post_processing" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'post_processing')
  #       get :new, status: 'post_processing_user_input', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status digitizing" do
  #     it "should return status 422" do
  #       job = create(:job, status: 'digitizing')
  #       get :new, status: 'post_processing_user_input', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 422
  #     end
  #   end
  # end

  # describe "post_processing_user_input_end" do
  #   context "job has status post_processing_user_input" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'post_processing')
  #       get :complete, status: 'post_processing_user_input', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status digitizing" do
  #     it "should return status 422" do
  #       job = create(:job, status: 'digitizing')
  #       get :complete, status: 'post_processing_user_input', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 422
  #     end
  #   end
  # end

  # describe "quality_control_begin" do
  #   context "job has status quality_control" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'quality_control')
  #       get :new, status: 'quality_control', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  #   context "job has status digitizing" do
  #     it "should return status 200" do
  #       job = create(:job, status: 'digitizing')
  #       get :new, status: 'quality_control', id: job.id, api_key: @api_key
  #       expect(response.status).to eq 200
  #     end
  #   end
  # end
end
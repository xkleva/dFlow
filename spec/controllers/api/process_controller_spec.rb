require 'rails_helper'

RSpec.describe Api::ProcessController, :type => :controller do
  
  before :each do
    WebMock.disable_net_connect! 
    @api_key = APP_CONFIG["api_key_users"].first["api_key"]
  end
  after :each do
    WebMock.allow_net_connect!
  end

  describe "request_job" do
    context "a job with process CONFIRMATION exists" do
      it "should return a job" do
        job = create(:job);

        job.flow_step.enter!
        
        get :request_job, code: 'CONFIRMATION', api_key: @api_key
        
        expect(response.status).to eq 200
        expect(json['job']).to_not be nil
        expect(json['job']['status']).to eq 'Waiting to begin'
      end
    end
  end

  describe "update_process" do
    context "sends a progress message" do
      it "should accept message and save for job" do
        job = create(:job)

        post :update_process, job_id: job.id, status: 'progress', msg: 'Everything is running fine!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'Waiting to begin'
        expect(json['job']['flow_step']['process_msg']).to eq 'Everything is running fine!'
      end
    end

    context "sends a fail message" do
      it "should quarantine job with message" do
        job = create(:job)

        post :update_process, job_id: job.id, status: 'fail', msg: 'Something was missing!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'Waiting to begin'
        expect(json['job']['quarantined']).to be_truthy
      end
    end

    context "sends a success message" do
      it "should move job to next status" do
        job = create(:job)

        post :update_process, job_id: job.id, status: 'success', msg: 'All done!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'First manual process'
      end
    end
  end
end

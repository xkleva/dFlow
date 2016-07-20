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
        
        get :request_job, code: 'CONFIRMATION', api_key: @api_key
        
        expect(response.status).to eq 200
        expect(json['job']).to_not be nil
        expect(json['job']['status']).to eq 'Waiting to begin'
      end
    end
    context "a job with process CONFIRMATION exists, but is already started" do
      it "should return message saying there are jobs running" do
        job = create(:job);

        job.flow_step.start!
        
        get :request_job, code: 'CONFIRMATION', api_key: @api_key
        
        expect(response.status).to eq 200
        expect(json['job']).to be nil
        expect(json['msg']).to include("There are jobs running for process")
      end
    end
  end

  describe "update_process" do
    context "sends a progress message" do
      it "should accept message and save for job" do
        job = create(:job)

        get :update_process, job_id: job.id, step: 10, status: 'progress', msg: 'Everything is running fine!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'Waiting to begin'
        expect(json['job']['flow_step']['status']).to eq 'Everything is running fine!'
      end
    end

    context "sends a fail message" do
      it "should quarantine job with message" do
        job = create(:job)

        get :update_process, job_id: job.id, step: 10, status: 'fail', msg: 'Something was missing!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'Waiting to begin'
        expect(json['job']['quarantined']).to be_truthy
      end
    end

    context "sends a success message" do
      it "should move job to next status" do
        job = create(:job)

        get :update_process, job_id: job.id, step: 10, status: 'success', msg: 'All done!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'First manual process'
        expect(json['job']['current_flow_step']).to eq 20
      end

      it "should not affect previous flow steps" do
        job = create(:job)
        job.flow_step.start!
        timestamp1 = job.flow_step.started_at
        job.flow_step.finish!

        get :update_process, job_id: job.id, step: 20, status: 'success', msg: 'All done!', api_key: @api_key

        job.reload

        timestamp2 = FlowStep.job_flow_step(job_id: job.id, flow_step: 10).started_at
        expect(response.status).to be 200
        expect(timestamp1 == timestamp2).to be_truthy
      end
    end

    context "sends a success message with wrong step nr" do
      it "should return 402" do
        job = create(:job)

        get :update_process, job_id: job.id, step: 20, status: 'success', msg: 'All done!', api_key: @api_key

        expect(response.status).to be 422
        expect(json['job']).to be nil
        expect(json['error']['msg']).to include("Given step number does not correlate to current flow_step")
      end
    end

    context "sends a start message with correct step nr" do
      it "should start job" do
        job = create(:job)

        get :update_process, job_id: job.id, step: 10, status: 'start', msg: 'Started!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['current_flow_step']).to eq 10
        expect(json['job']['flow_step']['started_at']).to_not be nil
      end
    end

    context "sends a start message with wrong step nr" do
      it "should return error code" do
        job = create(:job)

        get :update_process, job_id: job.id, step: 20, status: 'start', msg: 'Started!', api_key: @api_key

        expect(response.status).to be 422
        expect(json['job']).to be nil
        expect(json['error']['msg']).to include("Given step number does not correlate to current flow_step")
      end
    end

    context "sends a start message for already started job" do
      it "should return error code" do
        job = create(:job)
        job.flow_step.start!

        get :update_process, job_id: job.id, step: 10, status: 'start', msg: 'Started!', api_key: @api_key

        expect(response.status).to be 422
        expect(json['job']).to be nil
        expect(json['error']['msg']).to include("Given step number is already started")
      end
    end

  end
end

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
    context "a job with status waiting_for_package_metadata_import exists" do
      it "should return a job" do
        create(:job, current_flow_step: 70);
        
        get :request_job, code: 'PACKAGE_METADATA_IMPORT', api_key: @api_key
        
        expect(response.status).to eq 200
        expect(json['job']).to_not be nil
        expect(json['job']['status']).to eq 'package_metadata_import'
      end
    end
  end

  describe "update_process" do
    context "sends a progress message" do
      it "should accept message and save for job" do
        job = create(:job, status: 'package_metadata_import')

        post :update_process, job_id: job.id, status: 'progress', msg: 'Everything is running fine!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'package_metadata_import'
        expect(json['job']['process_message']).to eq 'Everything is running fine!'
      end
    end

    context "sends a fail message" do
      it "should quarantine job with message" do
        job = create(:job, status: 'package_metadata_import')

        post :update_process, job_id: job.id, status: 'fail', msg: 'Something was missing!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq 'package_metadata_import'
        expect(json['job']['quarantined']).to be_truthy
      end
    end

    context "sends a success message" do
      it "should move job to next status" do
        job = create(:job, status: 'package_metadata_import')

        post :update_process, job_id: job.id, status: 'success', msg: 'All done!', api_key: @api_key

        expect(response.status).to be 200
        expect(json['job']['status']).to eq job.status_object.next_status.name
      end
    end
  end
end

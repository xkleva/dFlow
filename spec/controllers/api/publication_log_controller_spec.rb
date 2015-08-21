require 'rails_helper'

RSpec.describe Api::PublicationLogController, :type => :controller do
  
  before :each do
    WebMock.disable_net_connect! 
    @api_key = APP_CONFIG["api_key_users"].first["api_key"]
  end
  after :each do
    WebMock.allow_net_connect!
  end

  describe "index" do
    context "for a valid job id with publication logs" do
      it "should return a list of publication logs" do
        job = create(:job)
        create_list(:publication_log, 2, job_id: job.id)

        get :index, job_id: job.id

        expect(json['publication_logs'].count).to eq 2
      end
    end

    context "without a job_id" do
      it "should return an error code" do

        get :index

        expect(json['error']).to_not be nil
        expect(response).to_not be_success
      end
    end
  end

  describe "create" do
    context "a valid publication log and an existing job" do
      it "should create publication log for job" do
        job = create(:job)
        publication_log = build(:publication_log, job_id: job.id)

        post :create, publication_log: publication_log.as_json, api_key: @api_key

        expect(response).to be_success

        job.reload

        expect(job.publication_logs.count).to eq 1
      end
    end
  end

end

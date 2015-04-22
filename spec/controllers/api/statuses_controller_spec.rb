require 'rails_helper'

describe Api::StatusesController do
  before :each do
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
    context "job does not exist" do
      it "should return status 404" do
        get :digitizing_begin, id: -1, api_key: @api_key
        expect(response.status).to eq 404
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

  describe "post_processing_begin" do
    context "job has status post_processing" do
      it "should return status 200" do
        job = create(:job, status: 'post_processing')
        get :post_processing_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :post_processing_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "post_processing_end" do
    context "job has status post_processing" do
      it "should return status 200" do
        job = create(:job, status: 'post_processing')
        get :post_processing_end, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :post_processing_end, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "post_processing_user_input_begin" do
    context "job has status post_processing" do
      it "should return status 200" do
        job = create(:job, status: 'post_processing')
        get :post_processing_user_input_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :post_processing_user_input_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "post_processing_user_input_end" do
    context "job has status post_processing_user_input" do
      it "should return status 200" do
        job = create(:job, status: 'post_processing')
        get :post_processing_user_input_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :post_processing_user_input_end, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "quality_control_begin" do
    context "job has status quality_control" do
      it "should return status 200" do
        job = create(:job, status: 'quality_control')
        get :quality_control_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :quality_control_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "waiting_for_mets_control_begin" do
    context "job has status waiting_for_mets_control" do
      it "should return status 200" do
        job = create(:job, status: 'waiting_for_mets_control')
        get :waiting_for_mets_control_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :waiting_for_mets_control_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "mets_control_begin" do
    context "job has status mets_control" do
      it "should return status 200" do
        job = create(:job, status: 'mets_control')
        get :mets_control_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :mets_control_begin, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end

  describe "mets_control_end" do
    context "job has status mets_control" do
      it "should return status 200" do
        job = create(:job, status: 'mets_control')
        get :mets_control_end, id: job.id, api_key: @api_key
        expect(response.status).to eq 200
      end
    end
    context "job has status digitizing" do
      it "should return status 422" do
        job = create(:job, status: 'digitizing')
        get :mets_control_end, id: job.id, api_key: @api_key
        expect(response.status).to eq 422
      end
    end
  end
end
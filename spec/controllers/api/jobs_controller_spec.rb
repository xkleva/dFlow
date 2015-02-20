require "rails_helper"

RSpec.configure do |c|
  c.include ModelHelper
end

describe Api::JobsController do
  before :each do
    WebMock.allow_net_connect!
    config_init
    @api_key = Rails.application.config.api_key
  end
  after :each do
    WebMock.allow_net_connect!
  end

  describe "GET index" do
    context "with existing jobs" do
      it "should return all jobs" do
        get :index, api_key: @api_key
        expect(json['jobs'].size).to be > 0
        expect(response.status).to eq 200
      end
    end
  end

  describe "GET show" do
    context "with existing job" do
      it "should return full job object data" do
        get :show, api_key: @api_key, id: 1
        expect(json['job'].size).to be > 0
        expect(response.status).to eq 200
        expect(json['job']['breadcrumb']).to be_kind_of(Array)
      end
    end

    context "with non-existing job" do
      it "should return 404" do
        get :show, api_key: @api_key, id: 9999999
        expect(response.status).to eq 404
      end
    end
  end

  describe "GET job_metadata" do
    context "with invalid attributes" do
      it "returns a json message" do
        get :job_metadata, api_key: @api_key, job_id: "wrong"
        expect(json['error']).to_not be nil
      end
    end
    context "with valid attributes" do
      it "Returns metadata" do
        get :job_metadata, api_key: @api_key, job_id: 1
        expect(json['error']).to be nil
      end
    end
  end
  describe "GET update_metadata" do
    context "with invalid attributes" do
      it "returns a json message" do
        get :update_metadata, api_key: @api_key, job_id: "wrong", key: "0001", metadata: {}
        expect(json['error']).to_not be nil
      end
    end
    context "with valid attributes" do
      it "Returns success and updates metadata" do
        get :update_metadata, api_key: @api_key, job_id: 1, key: "0001", metadata: {type: "test"}
        expect(json['error']).to be nil
      end
    end
  end

  describe "Create job" do
    context "with valid job parameters" do
      it "should create job without errors" do
        post :create, api_key: @api_key, job: {source: 'libris', treenode_id: '3', name: 'the jobname', comment: 'comment', title: 'The best book ever', catalog_id: '1234', copyright: 'true'}
        expect(json['error']).to be nil
      end
      it "should return the created object" do
        post :create, api_key: @api_key, job: {source: 'libris', treenode_id: '3', name: 'the jobname', comment: 'comment', title: 'The best book ever', catalog_id: '1234', copyright: 'false'}
        expect(json['job']).not_to be nil
        pp json['job']
        expect(json['job']['id']).not_to be nil
      end
    end
    context "with invalid job parameters" do
      it "should return an error message" do
        post :create, api_key: @api_key, job: {source: 'libris', cataloz_id: '1234', title: 'Bamse och hens vänner', treenode_id: '3', name: 'Bamse-jobbet', comment: 'comment'}
        expect(json['error']).to_not be nil
      end
    end
  end

  describe "GET index" do
    context "pagination" do
      it "should return metadata about pagination" do
        Job.per_page = 4
        get :index
        expect(json['jobs']).to_not be_empty
        expect(json['jobs'].count).to eq(4)
        #expect(json['meta']['query']['query']).to eq("Test")
        expect(json['meta']['query']['total']).to eq(5)
        expect(json['meta']['pagination']['pages']).to eq(2)
        expect(json['meta']['pagination']['page']).to eq(1)
        expect(json['meta']['pagination']['next']).to eq(2)
        expect(json['meta']['pagination']['previous']).to eq(nil)
        expect(json['meta']['pagination']['per_page']).to eq(4)
      end
      it "should return paginated second page when given page number" do
        Job.per_page = 4
        get :index, page: 2
        expect(json['jobs']).to_not be_empty
        expect(json['jobs'].count).to eq(1)
        #expect(json['meta']['query']['query']).to eq("Test")
        expect(json['meta']['query']['total']).to eq(5)
        expect(json['meta']['pagination']['pages']).to eq(2)
        expect(json['meta']['pagination']['page']).to eq(2)
        expect(json['meta']['pagination']['next']).to eq(nil)
        expect(json['meta']['pagination']['previous']).to eq(1)
      end
      it "should return first page when given out of bounds page number" do
        Job.per_page = 4
        get :index, page: 20000000000
        expect(json['jobs']).to_not be_empty
        expect(json['jobs'].count).to eq(4)
        #expect(json['meta']['query']['query']).to eq("Test")
        expect(json['meta']['query']['total']).to eq(5)
        expect(json['meta']['pagination']['pages']).to eq(2)
        expect(json['meta']['pagination']['page']).to eq(1)
        expect(json['meta']['pagination']['next']).to eq(2)
        expect(json['meta']['pagination']['previous']).to eq(nil)
      end
    end
  end

end

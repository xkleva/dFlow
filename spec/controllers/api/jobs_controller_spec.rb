# -*- coding: utf-8 -*-
require "rails_helper"

describe Api::JobsController do
  before :each do
    WebMock.disable_net_connect! 
    @api_key = APP_CONFIG["api_key_users"].first["api_key"]
  end
  after :each do
    WebMock.allow_net_connect!
  end

  describe "GET index" do
    context "with existing jobs" do
      it "should return all jobs" do
        create_list(:job,10)
        
        get :index, api_key: @api_key
        
        expect(json['jobs'].size).to be > 0
        expect(response.status).to eq 200
      end
    end

    context "for a given array of sources" do
      it "should filter list based on sources" do
        create_list(:job, 10, source: 'libris')
        create_list(:job, 2, source: 'document')
        create_list(:job, 3, source: 'letter')

        get :index, api_key: @api_key, sources: ['document', 'letter']

        expect(json['jobs'].count).to eq 5
      end
    end
  end

  describe "GET show" do
    context "with existing job" do
      it "should return full job object data" do
        job = create(:job, id: 1)
        
        get :show, api_key: @api_key, id: job.id
        
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

    context "when requesting format XML" do
      it "should return the job source xml" do
        job = create(:job)
        # Placeholder, minimal XML.
        job.xml = '<?xml version="1.0" encoding="UTF-8"?><xsearch xmlns:marc="http://www.loc.gov/MARC21/slim" to="1" from="1" records="1"><collection xmlns="http://www.loc.gov/MARC21/slim"><record></record></collection></xsearch>'
        job.save
        get :show, api_key: @api_key, id: job.id, format: :xml
        expect(response.header['Content-Type']).to match('application/xml')
        expect(response.body).to eq(job.xml)
      end
    end
  end

  describe "Create job" do
    context "with valid job parameters" do
      it "should create job without errors" do
        treenode = create(:child_treenode)
        
        post :create, api_key: @api_key, job: {source: 'libris', treenode_id: treenode.id, name: 'the jobname', comment: 'comment', title: 'The best book ever', catalog_id: '1234', copyright: true, flow: 'VALID_FLOW'}
        
        expect(json['error']).to be nil
      end
      it "should return the created object" do
        treenode = create(:treenode)
        
        post :create, api_key: @api_key, job: {source: 'libris', treenode_id: treenode.id, name: 'the jobname', comment: 'comment', title: 'The best book ever', catalog_id: '1234', copyright: 'false', flow: 'VALID_FLOW'}
        
        expect(json['job']).not_to be nil
        expect(json['job']['id']).not_to be nil
        expect(json['job']['name']).to eq('the jobname')
        expect(json['job']['copyright']).to eq(false)
      end
    end
    context "with invalid job parameters" do
      it "should return an error message" do
        treenode = create(:treenode)
        
        post :create, api_key: @api_key, job: {source: 'libris', cataloz_id: '1234', title: 'Bamse och hens vänner', treenode_id: treenode.id, name: 'Bamse-jobbet', comment: 'comment'}
        
        expect(json['error']).to_not be nil
      end
    end

    context "with a provided ID" do
      it "should create job and return JSON representation of that job" do
        job_id = 90000
        job_name = "The Jobb with the custom ID"
        treenode = create(:treenode)
        
        post :create, api_key: @api_key, force_id: "#{job_id}", job: {source: 'libris', treenode_id: treenode.id, name: job_name, comment: 'comment', title: 'The best book ever', catalog_id: '1234', copyright: 'false', flow: 'VALID_FLOW'}
        
        expect(json['error']).to be nil
        expect(json['job']).not_to be nil
        expect(json['job']['id']).to eq(job_id)
        expect(json['job']['name']).to eq(job_name)
      end
    end
  end

  describe "Validate job" do
    context "with valid job parameters" do
      it "should validate job without errors" do
        treenode = create(:child_treenode)
        
        post :create, api_key: @api_key, job: {source: 'libris', treenode_id: treenode.id, name: 'the jobname', comment: 'comment', title: 'The best book ever', catalog_id: '1234', copyright: true, flow: "VALID_FLOW"}, validate_only: true
        
        expect(json['error']).to be nil
        expect(json['job']['id']).to be_nil
      end
    end

    context "with invalid job parameters" do
      it "should return an error message" do
        treenode = create(:treenode)
        
        post :create, api_key: @api_key, job: {source: 'libris', cataloz_id: '1234', title: 'Bamse och hens vänner', treenode_id: treenode.id, name: 'Bamse-jobbet', comment: 'comment'}, validate_only: true
        
        expect(json['error']).to_not be nil
      end
    end

    context "with invalid treenode_id parameter" do
      it "should return an error message" do
        treenode = create(:treenode)
        
        post :create, api_key: @api_key, job: {source: 'libris', catalog_id: '1234', title: 'Bamse och hens vänner', name: 'Bamse-jobbet', comment: 'comment'}, validate_only: true
        
        expect(json['error']).to_not be nil
      end
    end
  end

  describe "GET index" do
    context "pagination" do
      it "should return metadata about pagination" do
        Job.destroy_all
        Job.per_page = 4
        number_of_jobs = 40
        create_list(:job, number_of_jobs)
        
        get :index
        
        expect(json['jobs']).to_not be_empty
        expect(json['jobs'].count).to eq(4)
        #expect(json['meta']['query']['query']).to eq("Test")
        expect(json['meta']['query']['total']).to eq(number_of_jobs)
        expect(json['meta']['pagination']['pages']).to eq(10)
        expect(json['meta']['pagination']['page']).to eq(1)
        expect(json['meta']['pagination']['next']).to eq(2)
        expect(json['meta']['pagination']['previous']).to eq(nil)
        expect(json['meta']['pagination']['per_page']).to eq(4)
      end
      it "should return paginated second page when given page number" do
        Job.destroy_all
        Job.per_page = 4
        number_of_jobs = 40
        create_list(:job, number_of_jobs)
        
        get :index, page: 2
        
        expect(json['jobs']).to_not be_empty
        expect(json['jobs'].count).to eq(4)
        #expect(json['meta']['query']['query']).to eq("Test")
        expect(json['meta']['query']['total']).to eq(40)
        expect(json['meta']['pagination']['pages']).to eq(10)
        expect(json['meta']['pagination']['page']).to eq(2)
        expect(json['meta']['pagination']['next']).to eq(3)
        expect(json['meta']['pagination']['previous']).to eq(1)
      end
      it "should return first page when given out of bounds page number" do
        Job.destroy_all
        Job.per_page = 4
        number_of_jobs = 40
        create_list(:job, number_of_jobs)
        
        get :index, page: 20000000000
        
        expect(json['jobs']).to_not be_empty
        expect(json['jobs'].count).to eq(4)
        #expect(json['meta']['query']['query']).to eq("Test")
        expect(json['meta']['query']['total']).to eq(40)
        expect(json['meta']['pagination']['pages']).to eq(10)
        expect(json['meta']['pagination']['page']).to eq(1)
        expect(json['meta']['pagination']['next']).to eq(2)
        expect(json['meta']['pagination']['previous']).to eq(nil)
      end
    end
  end

  describe "GET index" do
    context "query" do
      before :each do
        @jobs = create_list(:job, 10)
        @testjob1 = create(:job, title: "My very Special title")
        @testjoblist = create_list(:job, 5, name: "Anothername")
      end

      it "should return filtered list when using query parameter" do
        Job.per_page = 99999999999
        get :index, query: "special"
        expect(json['jobs'].count).to eq(1)
        expect(json['jobs'][0]['id']).to eq(@testjob1.id)
      end

      it "should return paginated filtered list when using query parameter" do
        Job.per_page = 4
        get :index, query: "anothername"
        expect(json['jobs'].count).to eq(4)
        expect(json['meta']['pagination']['pages']).to eq(2)
        expect(json['meta']['pagination']['page']).to eq(1)
        expect(json['meta']['pagination']['next']).to eq(2)
        expect(json['meta']['pagination']['previous']).to eq(nil)
      end

      it "should return second page of paginated filtered list when using query parameter and page" do
        Job.per_page = 4
        get :index, query: "anothername", page: 2
        expect(json['jobs'].count).to eq(1)
        expect(json['meta']['pagination']['pages']).to eq(2)
        expect(json['meta']['pagination']['page']).to eq(2)
        expect(json['meta']['pagination']['next']).to eq(nil)
        expect(json['meta']['pagination']['previous']).to eq(1)
      end
    end
    context "quarantined" do

      it "should return filtered list when using quarantined parameter" do
        Job.per_page = 99999999999
        @jobs = create_list(:job, 10)
        @quarantined_jobs = create_list(:job, 5, quarantined: true)
        
        get :index, quarantined: true
        
        expect(json['jobs'].count).to eq(5)
      end

      it "should return filtered list when using quarantined and query parameter" do
        Job.per_page = 99999999999
        create_list(:job, 10)
        create_list(:job, 5, title: "My very special title")
        create_list(:job, 7, quarantined: true, title: "My very special title")
        create_list(:job, 4, quarantined: true)
        
        get :index, quarantined: true, query: "special"
        
        expect(json['jobs'].count).to eq(7)
      end

      it "should return filtered list when using quarantined and query parameter" do
        Job.per_page = 99999999999
        create_list(:job, 10)
        create_list(:job, 5, title: "My very special title")
        create_list(:job, 7, quarantined: true, title: "My very special title")
        create_list(:job, 4, quarantined: true)
        
        get :index, quarantined: false, query: "special"
        
        expect(json['jobs'].count).to eq(5)
      end

    end
  end

  describe "PUT update" do
    context "with valid values" do
      it "should return an updated job" do
        job = create(:job)
        job.name = "NewName"
        
        post :update, api_key: @api_key, id: job.id, job: job.as_json
        
        expect(json['job']).to_not be nil
        expect(json['job']['name']).to eq 'NewName'
        expect(response.status).to eq 200
      end
    end
    context "without metadata key" do
      it "should not update metadata" do
        job = create(:job, metadata: {type_of_record: 'test'}.to_json)
        job.name = "NewName"
        
        post :update, api_key: @api_key, id: job.id, job: job.as_json
        
        json_hash = {type_of_record: 'test'}.as_json

        expect(json['job']).to_not be nil
        expect(json['job']['name']).to eq 'NewName'
        expect(json['job']['metadata']).to eq json_hash
        expect(response.status).to eq 200
      end
    end
    context "with invalid values" do
      it "should return an error message" do
        job = create(:job)
        job.copyright = nil
        
        post :update, api_key: @api_key, id: job.id, job: job.as_json
        
        expect(json['error']).to_not be nil
        expect(response.status).to eq 404
      end
    end
    context "with quarantine flag" do
      it "should return an updated job" do
        job = create(:job)
        job.quarantined = true

        post :update, api_key: @api_key, id: job.id, job: {"quarantined" => true, "message" => "Quarantined for testing purposes"}
        
        expect(json['error']).to be nil
        expect(response.status).to eq 200
        expect(json['job']['name']).to eq job.name
        expect(json['job']['quarantined']).to be_truthy
      end
    end
  end

  describe "DELETE delete" do
    context "an existing job" do
      it "should return 200" do
        job = create(:job)
        
        delete :destroy, api_key: @api_key, id: job.id
        
        expect(response.status).to eq 200

        job2 = Job.find_by_id(job.id)
        
        expect(job2).to be nil
      end
    end
  end

  describe "GET restart" do
    context "for an existing job" do
      it "should return job" do
        job = create(:job, current_flow_step: 20, id: 666)

        get :restart, api_key: @api_key, id: job.id

        expect(response.status).to eq 200
        expect(json['job']['current_flow_step']).to eq 10
      end
    end
  end

  describe "GET quarantine" do
    context "for an unquarantined job" do
      it "should return job" do
        job = create(:job)

        get :quarantine, api_key: @api_key, id: job.id, message: "Quarantine message"

        expect(response.status).to eq 200
        expect(json['job']['quarantined']).to eq true
      end
    end
  end

  describe "GET unquarantine" do
    context "for a quarantined job" do
      it "should return job" do
        job = create(:job)
        job.quarantine!(msg: "Quarantined")

        get :unquarantine, api_key: @api_key, id: job.id

        expect(response.status).to eq 200
        expect(json['job']['quarantined']).to eq false
      end
    end
  end

  describe "GET new_flow_step" do
    context "for a job with flow steps finished" do
      it "should return job to given flow step" do
        job = create(:job, current_flow_step: 30)
        
        get :new_flow_step, api_key: @api_key, id: job.id, step: 20

        expect(response.status).to eq 200
        job.reload
        expect(job.flow_step.step).to eq 20
      end
    end
  end

end

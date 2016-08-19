# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.describe Job, :type => :model do
  subject {build(:job)}
  before :each do
    login_users
  end

  # RELATIONS
  it {should belong_to(:treenode)}
  it {should belong_to(:flow)}
  it {should have_many(:job_activities)}
  it {should have_many(:publication_logs)}
  it {should have_many(:flow_steps)}

  # VALIDATIONS
  describe "id" do
    it {should validate_uniqueness_of(:id)}
  end

  describe "title" do
    it {should validate_presence_of(:title)}
  end

  describe "catalog_id" do
    it {should validate_presence_of(:catalog_id)}
  end
  
  describe "treenode" do
    it {should validate_presence_of(:treenode_id)}
  end

  describe "source" do
    it {should validate_presence_of(:source)}
    it {should_not allow_value("no-such-source").for(:source)}
  end

  describe "copyright" do
    it {should allow_value(true,false).for(:copyright)}
    it {should_not allow_value(nil).for(:copyright)}
  end

  describe "xml_validity" do
    it "should return error if xml is invalid" do
      job = build(:job, xml: '<xll><aas>')

      expect(job.valid?).to be false
      expect(job.errors.messages[:xml]).to include("XML must be valid")
    end
  end

  describe "flow" do
    it {should validate_presence_of(:flow)}
    it "should validate flow" do
      job = build(:job, flow: create(:flow, steps: YAML.load_file("#{Rails.root}/spec/support/flow_mocks/steps_mock.yml")['MISSING_START'].to_json))

      job.validate_flow

      expect(job.errors.messages[:flow]).to_not be nil
    end
  end

  describe "deleted_at" do
    it {should allow_value(nil).for(:deleted_at)}
    it {should allow_value(Time.now).for(:deleted_at)}
  end

  describe "deleted?" do
    context "deleted_at is set" do
      it "should return true" do
        job = create(:deleted_job)
        expect(job.deleted?).to be_truthy
      end
    end
    context "deleted_at is nil" do
      it "should return false" do
        job = create(:job)
        expect(job.deleted?).to be_falsy
      end
    end
  end


  describe "job_activities" do
    context "on create" do
      it "should create a JobActivity object" do
        job = create(:job)
        expect(job.job_activities.size).to eq 1
        expect(job.job_activities.first.username).to eq "TestUser"
      end
    end
  end

  describe "update_metadata_key" do
    context "insert new key" do
      it "should save new key value" do
        job = create(:job)
        data = {type: "testtype", page_count: 2}
        job.update_metadata_key("job", data)
        expect(JSON.parse(job.metadata)["job"]).not_to be nil
        expect(JSON.parse(job.metadata)["job"]["page_count"]).to be 2
      end
    end
    context "update existing key"
    it "should update metadata correctly" do
      job = create(:job)
      new_data = {type: "testtype", page_count: 100}
      job.update_metadata_key("job",new_data)
      expect(JSON.parse(job.metadata)["job"]["type"] == "testtype").to be true

      new_data = {type: "testtype2", page_count: 89}
      job.update_metadata_key("job",new_data)
      expect(JSON.parse(job.metadata)["job"]["type"] == "testtype2").to be true
      expect(JSON.parse(job.metadata)["job"]["page_count"] == 89).to be true
    end
  end

  describe "Update quarantined flag" do
    context "for unquarantined job" do
      it "should quarantine job and add log item" do
        job = create(:job)
        job.quarantine!(msg: "quarantined")
        expect(job.job_activities.count).to eq 2
      end
    end
    context "for quarantined job" do
      it "should do nothing" do
        job = create(:job, quarantined: true)
        job.quarantine!(msg: "Quarantined")
        expect(job.job_activities.count).to eq 1
      end
    end
    context "unquarantine with updated current_flow_step" do
      it "should recreate flow_steps" do
        job = create(:job)
        job.quarantine!(msg: "Quarantined for testing purposes")
        fs_old1 = FlowStep.job_flow_step(job_id: job.id, flow_step: 10)
        fs_old2 = FlowStep.job_flow_step(job_id: job.id, flow_step: 30)
        fs_old3 = FlowStep.job_flow_step(job_id: job.id, flow_step: 40)

        job.unquarantine!(step_nr: 30)
        fs_new1 = FlowStep.job_flow_step(job_id: job.id, flow_step: 10)
        fs_new2 = FlowStep.job_flow_step(job_id: job.id, flow_step: 30)
        fs_new3 = FlowStep.job_flow_step(job_id: job.id, flow_step: 40)

        expect(job.current_flow_step).to eq 30
        #expect(fs_old1.created_at == fs_new1.created_at).to be_truthy
        #expect(fs_old2.created_at != fs_new2.created_at).to be_truthy
        #expect(fs_old3.created_at != fs_new3.created_at).to be_truthy
      end
    end
  end

  describe "create_log_entry" do
    context "for valid job when switching quarantined" do
      it "should generate a JobActivity object" do
        job = create(:job)
        job.created_by = @api_key_user
        job.quarantine!(msg: "Quarantined")
        job.reload

        expect(job.job_activities.count).to eq 2
      end
    end
  end

  describe "create_pdf" do
    context "for a valid job" do
      it "should return a pdf object" do
        job = create(:job)
        expect(job.create_pdf).to_not be nil
      end
    end
  end

  describe "generate search_title" do
    it "should generate search data from job title" do
      job = create(:job)
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match(job.title)
    end

    it "should downcase data in search_title" do
      job = create(:job, title: "UppERCase")
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match("uppercase")
    end

    it "should strip diacritics from strings in search_title" do
      job = create(:job, title: "UppERCas\u00e9")
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match("uppercase")
    end

    it "should include author in search_title" do
      job = create(:job)
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match(job.author)
    end

    it "should work when author is empty" do
      job = create(:job, author: nil)
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to_not be_nil
    end

    it "should include name in search_title" do
      job = create(:job, name: "My own name")
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match("my own name")
    end

    it "should work when name is empty" do
      job = create(:job, name: nil)
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to_not be_nil
    end

    it "should include catalog_id in search_title" do
      job = create(:job, catalog_id: 1234567)
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match("1234567")
    end

    it "should include job_id in search_title" do
      job = create(:job, id: 998877665)
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match("998877665")
    end

    it "should include ordinal and chronological metadata in search_title" do
      job = create(:journal_job)
      expect(job.search_title).to be_nil
      job.build_search_title
      expect(job.search_title).to match("arg")
      expect(job.search_title).to match("september")
      expect(job.search_title).to match("dag 6")
      expect(job.search_title).to match("ar 1978")
    end
  end

  describe "generate missing search_titles" do
    it "should create search_title field for all jobs where it is null" do
      pre_indexed_jobs = create_list(:job, 10, search_title: "dummy")
      create_list(:job, 10)
      expect(Job.where(search_title: nil).count).to eq(10)
      Job.index_jobs
      expect(Job.where(search_title: nil).count).to eq(0)
      pre_indexed_jobs.each do |pre_indexed_job|
        job = Job.find_by_id(pre_indexed_job.id)
        expect(job.search_title).to match("dummy")
      end
    end
  end

  describe "create job with stepnr" do
    context "for a new job" do
      it "should set current flow step to given number" do
        job = create(:job, current_flow_step: 30)
        expect(job.flow_step.step).to eq 30
      end
      it "should set state according to given step" do
        job = create(:job, current_flow_step: 30)
        expect(job.state).to eq "ACTION"
      end
      it "should complete all previous steps" do
        job = create(:job, current_flow_step: 30)
        flow_step1 = FlowStep.job_flow_step(job_id: job.id, flow_step: 10)
        flow_step2 = FlowStep.job_flow_step(job_id: job.id, flow_step: 10)
        job.reload

        expect(flow_step1.entered?).to be_truthy
        expect(flow_step1.started?).to be_truthy
        expect(flow_step1.finished?).to be_truthy
        expect(flow_step2.entered?).to be_truthy
        expect(flow_step2.started?).to be_truthy
        expect(flow_step2.finished?).to be_truthy

        expect(job.current_flow_step).to eq 30
        expect(job.flow_step.entered?).to be_truthy
        expect(job.flow_step.started?).to be_falsey
      end
    end
  end
end

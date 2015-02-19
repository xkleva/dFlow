require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe Job, :type => :model do
  before :each do
    config_init
  end

  describe "create job" do
    it "should save a valid job object" do
      job = Job.new(title: "Test Job", catalog_id: 12345, source: "libris", treenode_id: 1, copyright: true)
      job.valid?
      pp job.errors
      expect(job.save).to be_truthy
    end

    it "should require title" do
      job = Job.new(catalog_id: 12345, source: "libris", treenode_id: 1)
      expect(job.save).to be_falsey
    end

    it "should require catalog_id" do
      job = Job.new(title: "Test Job", source: "libris", treenode_id: 1)
      expect(job.save).to be_falsey
    end

    it "should require source" do
      job = Job.new(title: "Test Job", catalog_id: 12345, treenode_id: 1)
      expect(job.save).to be_falsey
    end

    it "should require valid source" do
      job = Job.new(title: "Test Job", catalog_id: 12345, source: "no-such-source", treenode_id: 1)
      expect(job.save).to be_falsey
    end

    it "should require a valid treenode parent" do
      job = Job.new(title: "Test Job", catalog_id: 12345, source: "libris")
      expect(job.save).to be_falsey
    end

    it "should create a JobActivity object" do
      job = Job.create(title: "Test Job", catalog_id: 12345, source: "libris", treenode_id: 1, created_by: "TestUser", copyright: 'true')
      expect(job.job_activities.size).to eq 1
      expect(job.job_activities.first.username).to eq "TestUser"
    end
  end

	describe "update_metadata_key" do
		context "insert new key" do
			it "should save new key value" do
				job = Job.find(1)
				data = {type: "testtype", page_count: 2}
				job.update_metadata_key("job", data)
				expect(JSON.parse(job.metadata)["job"]).not_to be nil
				expect(JSON.parse(job.metadata)["job"]["page_count"]).to be 2
			end
		end
		context "update existing key"
		it "should update metadata correctly" do
			job = Job.find(1)
			new_data = {type: "testtype", page_count: 100}
			job.update_metadata_key("job",new_data)
			expect(JSON.parse(job.metadata)["job"]["type"] == "testtype").to be true

			new_data = {type: "testtype2", page_count: 89}
			job.update_metadata_key("job",new_data)
			expect(JSON.parse(job.metadata)["job"]["type"] == "testtype2").to be true
			expect(JSON.parse(job.metadata)["job"]["page_count"] == 89).to be true
		end
	end
end

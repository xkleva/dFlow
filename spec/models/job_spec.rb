require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe Job, :type => :model do
	before :each do

	end
	describe "create job" do
		context "from valid libris id" do
			it "should create a job object" do
				
			end
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
	describe "current_entry" do
		context "current is STARTING and scan_job" do
			it "should return proper Entry object" do
				job = Job.find(1)
				entry = job.current_entry
				expect(entry.state).to eq("PENDING")
			end
		end
		context "has no current entry" do
			it "should return nil" do
				job = Job.new(id: 1000, catalog_id: 1, source_id: 1)
				entry = job.current_entry
				expect(entry).to be nil
			end
		end
	end
end

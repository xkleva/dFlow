require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe ProcessModel, :type => :model do
	before :each do
		config_init
		@test_hash = {id: 1000, code: "test_process"}
		@test_model = ProcessModel.new(@test_hash)
		
		Rails.application.config.process_list << @test_hash
		@scan_job_model = ProcessModel.find_on_code("scan_job")
		@rename_files_model = ProcessModel.find_on_code("rename_files")
		@move_files_model = ProcessModel.find_on_code("move_files")
	end
	describe "initialize" do
		context "with correct hash object" do
			it "should create a ProcessModel object" do
				pm = ProcessModel.new(@test_hash)
				expect(pm).to be_instance_of ProcessModel
			end
		end
	end
	describe "find_on_code" do
		context "with non exisiting process_code" do
			it "should return nil" do
				pm = ProcessModel.find_on_code("dummy_code")
				expect(pm.nil?).to be true
			end
		end
		context "with existing process_code" do
			it "should return the correct ProcessModel object" do
				pm = ProcessModel.find_on_code("test_process")
				expect(pm.id == 1000).to be true
			end
		end
	end
	describe "entries" do
		context "with non existing state" do
			it "should return an empty array" do
				result = @test_model.entries("TEST_STATE")
				expect(result.nil?).to be false
				expect(result.respond_to?(:size)).to be true
				expect(result.empty?).to be true
			end
		end
		context "with existing state" do
			it "should return an array of entries" do
				result = @scan_job_model.entries("PENDING")
				expect(result.first).to be_instance_of Entry
			end
		end
	end
	describe "first_pending_job" do
		context "for process with no jobs pending" do
			it "should return nil" do
				expect(@test_model.first_pending_job).to be nil
			end
		end
		context "for process with jobs pending" do
			it "should return a job" do
				expect(@scan_job_model.first_pending_job).to be_instance_of Job
			end
		end
	end
	describe "update_state_for_job" do
		context "for invalid job_id" do
			it "should return false" do
				expect(@scan_job_model.update_state_for_job(999, "STARTED")).to be false
			end
		end
		context "for invalid state" do
			it "should return false" do
				expect(@scan_job_model.update_state_for_job(1, "TEST_STATE")).to be false
			end
		end
		context "for valid job and state" do
			it "should return true" do
				expect(@scan_job_model.update_state_for_job(1,"STARTED")).to be true
			end
			it "should update job state" do
				@scan_job_model.update_state_for_job(1,"STARTED")
				job = Job.find(1)
				entry = job.current_entry
				expect(entry.state).to eq("STARTED")
			end
		end
	end
	describe "startable" do
		context "method has no limitation" do
			it "should return true" do
				expect(@scan_job_model.startable?).to be true
			end
		end
		context "method has limitation which is met" do
			it "should return false" do
				expect(@rename_files_model.startable?).to be false
			end
		end
		context "method has limitation which is not met" do
			it "should return false" do
				expect(@move_files_model.startable?).to be true
			end
		end
	end
end
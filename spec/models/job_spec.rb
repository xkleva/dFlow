require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe Job, :type => :model do
  before :each do
    config_init
    login_users
  end

  describe "create job" do
    it "should save a valid job object" do
      job = Job.new(title: "Test Job", catalog_id: 12345, source: "libris", treenode_id: 1, copyright: true)
      job.valid?
      expect(job.save).to be_truthy
    end

    it {should validate_presence_of(:title)}

    it {should validate_presence_of(:catalog_id)}

    it {should validate_presence_of(:source)}

    it {should_not allow_value("no-such-source").for(:source)}

    it {should validate_presence_of(:treenode_id)}

    it {should allow_value(true).for(:copyright)}

    it {should allow_value(false).for(:copyright)}

    it {should_not allow_value(nil).for(:copyright)}

    it "should create a JobActivity object" do
      job = Job.create(title: "Test Job", catalog_id: 12345, source: "libris", treenode_id: 1, created_by: "TestUser", copyright: true)
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

  describe "switch status" do
    context "Switch to valid status" do
      before :each do
        @job = Job.find(1)
        @old_count = @job.job_activities.count
        @job.created_by = "api_key_user"
        @job.switch_status(Status.find_by_name('digitizing'))
        @job.save
        @job2 = Job.find(1)
      end
      it "should save new status" do
        expect(@job2.status).to eq 'digitizing'
      end
      it "should generate an activity entry" do
        expect(@job2.job_activities.count).to eq @old_count+1
      end
    end
  end

  describe "create_log_entry" do
    context "for valid job when switching status" do
      it "should generate a JobAtivity object" do
        job = Job.find(1)
        job.created_by = @api_user
        job.create_log_entry("STATUS", "StatusChange")
        job.save
        expect(job.job_activities.count).to eq 1
      end
    end
  end

  describe "create_pdf" do
    context "for a valid job" do
      it "should return a pdf object" do
        job = Job.find(1)
        expect(job.create_pdf).to_not be nil
      end
    end
  end

end

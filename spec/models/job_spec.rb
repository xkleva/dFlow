require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe Job, :type => :model do
  before :each do
    config_init
    login_users
  end

  describe "title" do
    it {should validate_presence_of(:title)}
  end

  describe "catalog_id" do
    it {should validate_presence_of(:catalog_id)}
  end

  describe "source" do
    it {should validate_presence_of(:source)}
    it {should_not allow_value("no-such-source").for(:source)}
  end

  describe "treenode" do
    it {should validate_presence_of(:treenode_id)}
  end

  describe "copyright" do
    it {should allow_value(true,false).for(:copyright)}
    it {should_not allow_value(nil).for(:copyright)}
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

describe "switch status" do
  context "Switch to valid status" do
    before :each do
      @job = create(:job, status: 'waiting_for_digitizing')
      @old_count = @job.job_activities.count
      @job.created_by = "api_key_user"
      @job.switch_status(Status.find_by_name('digitizing'))
      @job.save
      @job2 = Job.find(@job.id)
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
      job = create(:job)
      job.created_by = @api_user
      job.create_log_entry("STATUS", "StatusChange")
      job.save
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

end

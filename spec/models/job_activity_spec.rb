require 'rails_helper'

RSpec.configure do |c|
  c.include ModelHelper
end

RSpec.describe JobActivity, :type => :model do
  before :each do
    config_init
  end

  describe "create" do
    context "with valid parameters" do
      before :each do
        @activity = JobActivity.create(job_id: 1, username: "TestUser", event: "CREATE", message: "Activity was created")
      end
      it "should validate" do
        expect(@activity.valid?).to be true
      end
      it "should create a new object" do
        expect(@activity.id).to_not be nil
      end
      it "should have a timestamp" do
        expect(@activity.created_at).to_not be nil
      end
    end
    context "with an invalid event" do
      before :each do
        @activity = JobActivity.create(job_id: 1, username: "TestUser", event: "ZZZZ", message: "Activity was created")
      end
      it "should invalidate object" do
        expect(@activity.valid?).to be false
      end
      it "should return an error for field event" do
        expect(@activity.errors.messages[:event]).to_not be nil
      end
    end
    context "with an invalid job id" do
      before :each do
        @activity = JobActivity.create(job_id: -1, username: "TestUser", event: "CREATE", message: "Activity was created")
      end
      it "should invalidate object" do
        expect(@activity.valid?).to be false
      end
      it "should return an error for field job_id" do
        expect(@activity.errors.messages[:job]).to_not be nil
      end
    end
    context "with username set to nil" do
      before :each do
        @activity = JobActivity.create(job_id: 1, username: nil, event: "CREATE", message: "Activity was created")
      end
      it "should invalidate object" do
        expect(@activity.valid?).to be false
      end
      it "should return an error for field job_id" do
        expect(@activity.errors.messages[:username]).to_not be nil
      end
    end
    context "with username set to empty string" do
      before :each do
        @activity = JobActivity.create(job_id: 1, username: "", event: "CREATE", message: "Activity was created")
      end
      it "should invalidate object" do
        expect(@activity.valid?).to be false
      end
      it "should return an error for field job_id" do
        expect(@activity.errors.messages[:username]).to_not be nil
      end
    end
    context "with message set to nil" do
      before :each do
        @activity = JobActivity.create(job_id: 1, username: "TestUser", event: "CREATE", message: nil)
      end
      it "should validate object" do
        expect(@activity.valid?).to be true
      end
    end
  end
end

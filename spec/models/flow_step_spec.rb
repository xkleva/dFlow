require 'rails_helper'

RSpec.describe FlowStep, :type => :model do
  describe "step" do

    it "should fail on duplicate step ids for job" do
      job = build(:job)
      flow_step = create(:flow_step, step: 10, job: job)

      flow_step2 = build(:flow_step, step: 10, job: job)

      expect(flow_step2.valid?).to be_falsey
    end

    it "should succeed on duplicate step ids for job" do
      job = build(:job)
      flow_step = create(:flow_step, step: 10, job_id: job.id, aborted_at: DateTime.now)

      flow_step2 = build(:flow_step, step: 10, job_id: job.id)

      expect(flow_step2.valid?).to be_truthy
    end

    it {should_not allow_value('13abc').for(:step)}
    it {should allow_value('13').for(:step)}
  end

  describe "job" do
    it {should belong_to(:job)}
  end

  describe "description" do
    it {should_not validate_presence_of(:description)}
    it {should allow_value("Test desc").for(:description)}
  end

  describe "process" do
    it {should validate_presence_of(:process)}
    it {should_not allow_value("no-such-process").for(:process)}
    it {should allow_value("CONFIRMATION").for(:process)}
  end
end

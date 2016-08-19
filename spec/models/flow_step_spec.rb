require 'rails_helper'

RSpec.describe FlowStep, :type => :model do
  subject {build(:flow_step)}
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
    it {should validate_presence_of(:description)}
    it {should allow_value("Test desc").for(:description)}
  end

  describe "process" do
    it {should validate_presence_of(:process)}
    it {should_not allow_value("no-such-process").for(:process)}
    it {should allow_value("CONFIRMATION").for(:process)}
  end

  describe "validate_params" do
    context "for a process_object with a required param" do
      it "should validate presence of required params" do
        job = build(:job)
        flow_step = build(:flow_step, step: 10, job: job, process: "CONFIRMATION", params: "")
        expect(flow_step.valid?).to be_falsey
        expect(flow_step.errors.messages[:params].size).to eq 1
      end
    end
  end

  describe "params_hash" do
    context "empty params string" do
      it "should return an empty hash" do
        job = build(:job)
        flow_step = build(:flow_step, step: 10, job: job, params: "")

        expect(flow_step.params_hash).to eq Hash.new
      end
    end

    context "params string with value" do
      it "should return a hash" do
        job = build(:job)
        flow_step = build(:flow_step, step: 10, job: job, params: {"manual" => true}.to_json)
        
        hash = {'manual' => true}
        
        expect(flow_step.params_hash).to eq hash
      end
    end
  end

  describe "finish_step?" do
    context "for the last step of a flow" do
      it "should return true" do
        job = build(:job)
        flow_step = build(:flow_step, step: 40, job: job, goto_true: nil, goto_false: nil)

        expect(flow_step.finish_step?).to be_truthy
      end
    end
    context "for a non last step of a flow" do
      it "should return false" do
        job = build(:job)
        flow_step = build(:flow_step, step: 20, job: job, goto_true: 30, goto_false: nil)

        expect(flow_step.finish_step?).to be_falsey
      end
    end
  end

  describe "start_step?" do
    context "with parameter start set to true" do
      it "should return true" do
        flow_step = build(:flow_step, step: 10, params: {'start' => true}.to_json)

        expect(flow_step.start_step?).to be_truthy
      end
    end
    context "with parameter start not set" do
      it "should return false" do
        flow_step = build(:flow_step, :end_step, step: 10)

        expect(flow_step.start_step?).to be_falsey
      end
    end
  end

  describe "goto_true_step" do
    context "for step with a goto_true step" do
      it "should return a FlowStep object" do
        job = create(:job)
        flow_step = create(:flow_step, job: job, step: 100, goto_true: 200)
        flow_step2 = create(:flow_step, job: job, step: 200)

        expect(flow_step.goto_true_step).to be_a FlowStep
      end
    end
    context "for step with no goto_true step" do
      it "should return a FlowStep object" do
        flow_step = create(:flow_step, :end_step, goto_true: nil)

        expect(flow_step.goto_true_step).to be nil
      end
    end
  end

  describe "is_before?" do
    context "for a step two steps in front of given step" do
      it "should return true" do
        step1 = build(:flow_step, step: 30)

        expect(step1.is_before?(20)).to be_truthy
      end
    end

    context "for a step two steps behind front of given step" do
      it "should return true" do
        step1 = build(:flow_step, step: 20)

        expect(step1.is_before?(30)).to be_falsey
      end
    end

    context "for same step number as given step" do
      it "should return false" do
        step1 = build(:flow_step, step: 20)

        expect(step1.is_before?(20)).to be_falsey
      end
    end
  end

  describe "is_after?" do
    context "for a step two steps in front of given step" do
      it "should return false" do
        step1 = build(:flow_step, step: 10)

        expect(step1.is_after?(20)).to be_falsey
      end
    end

    context "for a step two steps behind front of given step" do
      it "should return true" do
        step1 = build(:flow_step, step: 20)

        expect(step1.is_after?(10)).to be_truthy
      end
    end

    context "for same step number as given step" do
      it "should return false" do
        step1 = build(:flow_step, step: 30)

        expect(step1.is_after?(20)).to be_falsey
      end
    end
  end

  describe "enter!" do
    context "for a flow_step not already entered" do
      it "should update entered_at flag and job" do
        job = create(:job)
        flow_step = job.flow_steps.where(step: 30).first
        
        flow_step.enter!
        job.reload

        expect(job.current_flow_step).to eq 30
        expect(flow_step.entered_at).to be_truthy
      end
    end
  end

  describe "start!" do
    context "for a flow_step not already started" do
      it "should update started_at flag and job" do
        job = create(:job)
        flow_step = job.flow_step
        
        flow_step.start!
        job.reload

        expect(job.current_flow_step).to eq 10
        expect(flow_step.started_at).to be_truthy
      end
    end

    context "for a flow_step already started" do
      it "should not do anything" do
        job = create(:job)
        flow_step = job.flow_step
        flow_step.start!
        timestamp = flow_step.started_at
        
        flow_step.start!
        job.reload

        expect(job.current_flow_step).to eq 10
        expect(flow_step.started_at).to eq timestamp
      end
    end
  end

  describe "finish!" do
    context "for a flow_step not already finished" do
      it "should update finished_at flag and job" do
        job = create(:job)
        flow_step = job.flow_step
        
        flow_step.start!
        flow_step.finish!
        job.reload

        expect(job.current_flow_step).to eq flow_step.goto_true
        expect(job.flow_step).to eq flow_step.goto_true_step
        expect(flow_step.finished_at).to be_truthy
      end
    end

    context "for a flow_step already finished" do
      it "should not do anything" do
        job = create(:job)
        flow_step = job.flow_step

        flow_step.start!
        flow_step.finish!
        timestamp = flow_step.finished_at
        
        flow_step.finish!
        job.reload

        expect(job.current_flow_step).to eq flow_step.goto_true
        expect(flow_step.finished_at).to eq timestamp
      end
    end
  end

  describe "main_state" do
    context "for an entered first flow_step" do
      it "should return START" do
        job = create(:job)

        expect(job.flow_step.main_state).to eq "START"
        expect(job.state).to eq "START"
      end
    end
    context "for an entered last step" do
      it "should return PROCESS" do
        job = create(:job, current_flow_step: 20)

        expect(job.flow_step.main_state).to eq "ACTION"
        expect(job.state).to eq "ACTION"
      end
    end
    context "for a finished last step" do
      it "should return FINISH" do
        job = create(:job, current_flow_step: 20)
        job.flow_step.finish!
        job.reload

        expect(job.flow_step.main_state).to eq "FINISH"
        expect(job.state).to eq "FINISH"
      end
    end
    context "for a manual ACTION step" do
      it "should return ACTION" do
        job = create(:job, current_flow_step: 20)

        expect(job.flow_step.main_state).to eq "ACTION"
        expect(job.state).to eq "ACTION"
      end
    end
  end

  describe "next_step" do
    context "where next step exists" do
      it "should return FlowStep" do
        job = create(:job)

        fs = job.flow_step.next_step
        expect(fs.step).to eq 30
      end
    end
    context "where next step has already been entered" do
      it "should return nil and quarantine job" do
        job = create(:job)
        fs = job.flow_step

        job.flow_step.finish!

        fs2 = fs.next_step
        job.reload

        expect(fs2).to eq nil
        expect(job.quarantined).to be_truthy
      end
    end
  end

  describe "abort!" do
    context "for an existing flow_step" do
      it "should set aborted_at flag for flow_step" do
        flow_step = create(:flow_step)
        flow_step.abort!

        expect(flow_step.aborted_at).to be_truthy
      end
    end
  end

end

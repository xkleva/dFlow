require 'rails_helper'

RSpec.describe Flow, :type => :model do
  describe "find" do
    context "for an existing flow name" do
      it "should return a flow" do
        flow = Flow.find("SCANGATE_FLOW")
        flow.generate_flow_steps(0)

        expect(flow).to be_truthy
        expect(flow.flow_steps).to_not be_empty
      end
    end
    context "for a non existing flow name" do
      it "should not return a flow" do
        expect{Flow.find("NOT_A_FLOW")}.to raise_error
      end
    end
  end

  describe "validate" do
    context "for a valid flow" do
      it "should return true" do
        flow = Flow.find("SCANGATE_FLOW")
        expect(flow.valid?).to be_truthy
      end
    end
    context "for an invalid flow" do
      it "should return false" do
        flow = Flow.find("MISSING_GOTO_STEP")
        expect(flow.valid?).to be_falsey
      end
    end
    context "for an invalid flow" do
      it "should return false" do
        flow = Flow.find("DUPLICATE_STEP")
        expect(flow.valid?).to be_falsey
      end
    end
    context "for an invalid flow" do
      it "should return false" do
        flow = Flow.find("MISSING_PARAMS")
        expect(flow.valid?).to be_falsey
      end
    end
  end

  describe "all" do
    it "should return a list of flows" do
      expect(Flow.all).to_not be_empty
      expect(Flow.all.first).to be_a Flow
    end
  end

  describe "apply_flow" do
    context "for a valid job and flow" do
      it "should generate flow_steps for job" do
        job = build(:job)
        flow = Flow.find("SCANGATE_FLOW")
        flow.apply_flow(job)

        expect(job.current_flow_step).to eq 10
        
        expect(job.flow_steps.count).to eq flow.flow_steps.count
      end
    end
  end

end

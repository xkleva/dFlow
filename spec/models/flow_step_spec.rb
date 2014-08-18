require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe FlowStep, :type => :model do
	before :each do
		
	end
	describe "next_step" do
		context "a valid job_id with following process" do
			it "should return the next flow_step" do
				step = FlowStep.find(1)
				job = Job.find(1)
				next_step = step.next_step(job,true)
				expect(next_step.id).to be 2
			end
		end
		context "a valid job_id with no following process" do
			it "should return nil" do
				step = FlowStep.find(3)
				job = Job.find(3)
				next_step = step.next_step(job,true)
				expect(next_step).to be nil
			end
		end
		context "a valid job id with condition" do
			it "should return the next flow_step" do
				step = FlowStep.find(4)
				job = Job.find(4)
				next_step = step.next_step(job)
				expect(next_step.id).to be 2
			end
		end
	end
	describe "evaluate_condition" do
		context "a valid flow step with condition" do
			it "should return true" do
				step = FlowStep.find(4)
				job = Job.find(4)
				result = step.evaluate_condition(job)
				expect(result).to be true
			end
		end
	end
end

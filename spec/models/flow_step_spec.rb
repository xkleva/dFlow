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
				next_step = step.next_step(1,true)
				expect(next_step.id).to be 2
			end
		end
		context "a valid job_id with no following process" do
			it "should return nil" do
				step = FlowStep.find(3)
				next_step = step.next_step(3,true)
				expect(next_step).to be nil
			end
		end
	end
end

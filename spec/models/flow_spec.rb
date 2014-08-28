require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe Flow, :type => :model do
	before :each do
		
	end
	describe "get_flow_steps" do
		context "a flow with flow steps" do
			it "should return an array with all flow steps" do
				flow = Flow.find(1)
				result = flow.get_flow_steps
				expect(result.size).to eq(3)
				expect(result[0]).to be_an_instance_of(FlowStep)
			end
		end
	end
end

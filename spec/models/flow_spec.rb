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
	describe "update_flow_steps" do
		context "a valid set of flow steps" do
			it "should update flow steps" do
				flow = Flow.find(1)
				new_steps = [{id: 7, process_id: 1, goto_true: 8, goto_false: 9}, {id: 8, process_id: 2, goto_true: 10},  {id: 9, process_id: 3, goto_true: 10},  {id: 10, process_id: 4}].to_json
				new_steps = JSON.parse(new_steps)
				flow.update_flow_steps(new_steps, 7)
				expect(flow.get_flow_steps.size).to eq(4)
			end
		end
	end
	describe "validate_flow_steps" do
		context "a valid set of flow steps" do
			it "should return true" do
				flow = Flow.find(1)
				new_steps = [{id: 7, process_id: 1, goto_true: 8, goto_false: 9}, {id: 8, process_id: 2, goto_true: 10},  {id: 9, process_id: 3, goto_true: 10},  {id: 10, process_id: 4}].to_json
				new_steps = JSON.parse(new_steps)
				result = flow.validate_flow_steps(new_steps,7)
				expect(result).to be true
			end
		end
		context "a set of flow steps missing assigned start id" do
			it "should return false" do
				flow = Flow.find(1)
				new_steps = [{id: 7, process_id: 1, goto_true: 8, goto_false: 9}, {id: 8, process_id: 2, goto_true: 10},  {id: 9, process_id: 3, goto_true: 10},  {id: 10, process_id: 4}].to_json
				new_steps = JSON.parse(new_steps)
				result = flow.validate_flow_steps(new_steps,6)
				expect(result).to be false
			end
		end
		context "a set of flow steps with no end point" do
			it "should return false" do
				flow = Flow.find(1)
				new_steps = [{id: 7, process_id: 1, goto_true: 8, goto_false: 9}, {id: 8, process_id: 2, goto_true: 10},  {id: 9, process_id: 3, goto_true: 10},  {id: 10, process_id: 4, goto_true: 8}].to_json
				new_steps = JSON.parse(new_steps)
				result = flow.validate_flow_steps(new_steps,7)
				expect(result).to be false
			end
		end
		context "a set of flow steps with a non connected step" do
			it "should return false" do
				flow = Flow.find(1)
				new_steps = [{id: 7, process_id: 1, goto_true: 8, goto_false: 9}, {id: 8, process_id: 2, goto_true: 10},  {id: 9, process_id: 3, goto_true: 10},  {id: 10, process_id: 4}, {id: 11, process_id: 4, goto_true: 8}].to_json
				new_steps = JSON.parse(new_steps)
				result = flow.validate_flow_steps(new_steps,7)
				expect(result).to be false
			end
		end
	end
end

require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

describe Api::FlowsController, :type => :controller do
	before :each do
		config_init
		@api_key = Rails.application.config.api_key
	end

	describe "GET get_flow" do
		context "an existing flow" do
			it "should return success message flow definition" do
				get :get_flow, api_key: @api_key, flow_id: 1
				expect(json['error']).to be nil
				expect(json['data']['flow_steps'].size).to eq(3)
			end
		end
		context "A non exisiting flow" do 
			it "should return an error message" do
				get :get_flow, api_key: @api_key, flow_id: 0
				expect(json['error']).to_not be nil
			end
		end
	end
	describe "POST update_flow_steps" do
		context "A valid flow setup" do
			it "should return a success message" do
				post :update_flow_steps, api_key: @api_key, flow_id: 1, new_start_position: 7, new_flow_steps: [{id: 7, process_id: 1, goto_true: 8, goto_false: 9}, {id: 8, process_id: 2, goto_true: 10},  {id: 9, process_id: 3, goto_true: 10},  {id: 10, process_id: 4}].to_json
				expect(json['error']).to be nil
			end
		end
		context "An ivalid flow setup" do
			it "should return an error message" do
				post :update_flow_steps, api_key: @api_key, flow_id: 1, new_start_position: 7, new_flow_steps: [{id: 7, process_id: 1, goto_true: 8, goto_false: 9}, {id: 8, process_id: 2, goto_true: 10},  {id: 9, process_id: 3, goto_true: 10}].to_json
				expect(json['error']).to_not be nil
			end
		end
	end
end

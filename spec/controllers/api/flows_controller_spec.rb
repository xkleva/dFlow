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
				expect(json['status']['code'] == 0).to be true
				expect(json['data']['flow_steps'].size).to eq(3)
			end
		end
		context "A non exisiting flow" do 
			it "should return an error message" do
				get :get_flow, api_key: @api_key, flow_id: 0
				expect(json['status']['code'] == -1).to be true
			end
		end
	end
end

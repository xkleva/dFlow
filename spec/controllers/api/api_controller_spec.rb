require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

describe Api::ApiController, :type => :controller do
	before :each do
		config_init
		@api_key = Rails.application.config.api_key
	end

	describe "GET check_connection" do
		context "with a valid key" do
			it "should return success status" do
				get :check_connection, api_key: @api_key
				expect(response.status).to eq 200
			end
		end
		context "with an invalid key" do
			it "should return error status" do
				get :check_connection, api_key: "wrong"
				expect(response.status).to eq 404
			end
		end
	end
end

require "rails_helper"

RSpec.configure do |c|
	c.include ModelHelper
end

describe Api::UsersController do
	before :each do
		config_init
		@api_key = Rails.application.config.api_key
	end

	describe "POST create" do
		context "with valid parameters" do
			it "should return a user object with id" do
			 post :create, api_key: @api_key, user: {username: "Testuser", name: "John Doe", role: "ADMIN"}
				expect(json['user']['id']).to_not be nil
				expect(response.status).to eq 201
			end
		end
		context "With invalid role" do
			it "should return an error object" do
				post :create, api_key: @api_key, user: {username: "Testuser", name: "John Doe", role: "FOO"}
				expect(json['error']).to_not be nil
				expect(json['user']).to be nil
				expect(response.status).to eq 422
			end
		end
	end

	describe "GET index" do
		context "with existing users" do
			it "should return a list of users" do
				get :index, api_key: @api_key
				expect(json['users']).to_not be nil
				expect(json['users'][0]['id']).to be_an(Integer)
			end
		end
	end
end
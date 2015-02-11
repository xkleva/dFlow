require "rails_helper"

RSpec.configure do |c|
	c.include ModelHelper
end

describe Api::TreenodesController do
	before :each do
		config_init
		@api_key = Rails.application.config.api_key
	end

	describe "POST create" do
		context "With valid parameters" do
			before :each do 
				post :create, api_key: @api_key, treenode: {name: "Tree node", parent_id: 1}
			end
			it "should return a treenode object with id" do
				expect(json['treenode']['id']).to_not be nil
			end
			it "should not return an error message" do
				expect(json['error']).to be nil
			end
			it "should return status code 201" do
				expect(response.status).to eq 201
			end
		end
		context "With invalid parent" do
			before :each do
				post :create, api_key: @api_key, treenode: {name: "Tree node", parent_id: -1}
			end
			it "should return an error object" do
				expect(json['error']).to_not be nil
			end
			it "should not return a treeenode object" do
				expect(json['treenode']).to be nil
			end
			it "should return status code 400" do
				expect(response.status).to eq 400
			end
		end

		context "With the same name as a sibling" do
			before :each do
				post :create, api_key: @api_key, treenode: {name: "Barn", parent_id: 1}
			end
			it "should return an error object" do
				expect(json['error']).to_not be nil
			end
			it "should not return a treeenode object" do
				expect(json['treenode']).to be nil
			end
			it "should return status code 400" do
				expect(response.status).to eq 400
			end
		end
	end
end
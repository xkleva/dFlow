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

	describe "GET show" do
		context "Existing treenode without children" do
			before :each do
				get :show, api_key: @api_key, id: 1
			end
			it "should return treenode object" do
				expect(json['treenode']).to_not be nil
			end
			it "should not return children objects" do
				expect(json['treenode']['children']).to be nil
			end
		end
		context "Exisiting treenode with children" do
			before :each do
				get :show, api_key: @api_key, id: 1, show_children: true
			end
			it "should return a treenode object" do
				expect(json['treenode']).to_not be nil
			end
			it "should return a list of children" do
				expect(json['treenode']['children']).to_not be nil
			end
			it "should return children with ids" do
				expect(json['treenode']['children'][0]['id']).to be_an(Integer)
			end
		end
		context "Non Existing treenode onject" do
			before :each do
				get :show, api_key: @api_key, id: -1
			end
			it "should return an error message" do
				expect(json['error']).to_not be nil
			end
			it "should not return a treenode object" do
				expect(json['treenode']).to be nil
			end
		end
	end
end
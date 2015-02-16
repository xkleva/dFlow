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
			it "should return status code 422" do
				expect(response.status).to eq 422
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
			it "should return status code 422" do
				expect(response.status).to eq 422
			end
		end

		context "With invalid name" do
			before :each do
				post :create, api_key: @api_key, treenode: {name: nil, parent_id: 1}
			end
			it "should return an error object" do
				expect(json['error']).to_not be nil
			end
			it "should not return a treeenode object" do
				expect(json['treenode']).to be nil
			end
			it "should return status code 422" do
				expect(response.status).to eq 422
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
		context "Non Existing treenode object" do
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
		context "Exisiting treenode with multi level breadcrumb" do
			before :each do
				get :show, api_key: @api_key, id: 3, show_breadcrumb: true
			end
			it "should return a treenode object" do
				expect(json['treenode']).to_not be nil
			end
			it "should return a list of breadcrumb nodes" do
				expect(json['treenode']['breadcrumb']).to_not be nil
			end
			it "should return breadcrumb nodes with ids" do
				expect(json['treenode']['breadcrumb'][0]['id']).to be_an(Integer)
			end
		end
		context "Asking for 'root' node" do
			before :each do
				get :show, api_key: @api_key, id: 'root', show_children: true
			end
			it "should return a treenode without id" do
				expect(json['treenode']).to_not be nil
				expect(json['treenode']['id']).to be nil
			end
			it "should return children with parent_id = nil" do
				expect(json['treenode']['children']).to_not be nil
				expect(json['treenode']['children'][0]['parent_id']).to be nil
			end
		end
	end

  describe "PUT update" do
    context "with valid values" do
      it "should return an updated treenode" do
        treenode = Treenode.find(1)
        treenode.name = "NewName"
        post :update, api_key: @api_key, id: treenode.id, treenode: treenode.as_json
        expect(json['treenode']).to_not be nil
        expect(json['treenode']['name']).to eq 'NewName'
      end
    end
    context "with invalid values" do
      it "should return an error message" do
        treenode = Treenode.find(1)
        treenode.name = ""
        post :update, api_key: @api_key, id: treenode.id, treenode: treenode.as_json
        expect(json['error']).to_not be nil
      end
    end
  end
end

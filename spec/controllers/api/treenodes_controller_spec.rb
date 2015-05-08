require "rails_helper"

describe Api::TreenodesController do
	before :each do
		@api_key = APP_CONFIG["api_key_users"].first["api_key"]
	end

	describe "POST create" do
		context "With valid parameters" do
			before :each do 
        treenode = create(:treenode)
				post :create, api_key: @api_key, treenode: {name: "Tree node", parent_id: treenode.id}
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
        treenode = create(:child_treenode)
				post :create, api_key: @api_key, treenode: {name: treenode.name, parent_id: treenode.parent_id}
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
        treenode = create(:treenode)
				post :create, api_key: @api_key, treenode: {name: nil, parent_id: treenode.id}
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
        treenode = create(:treenode)
				get :show, api_key: @api_key, id: treenode.id
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
        treenode = create(:treenode)
        create_list(:treenode, 10, parent_id: treenode.id)
				get :show, api_key: @api_key, id: treenode.id, show_children: true
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
		context "Existing treenode without jobs" do
			before :each do
        treenode = create(:treenode)
				get :show, api_key: @api_key, id: treenode.id
			end
			it "should return treenode object" do
				expect(json['treenode']).to_not be nil
			end
			it "should not return jobs objects" do
				expect(json['treenode']['jobs']).to be nil
			end
		end
		context "Exisiting treenode with jobs" do
			before :each do
        treenode = create(:treenode)
        create_list(:job, 20, treenode_id: treenode.id)
				get :show, api_key: @api_key, id: treenode.id, show_jobs: true
			end
			it "should return a treenode object" do
				expect(json['treenode']).to_not be nil
			end
			it "should return a list of jobs" do
				expect(json['treenode']['jobs']).to_not be nil
			end
			it "should return jobs with ids" do
				expect(json['treenode']['jobs'][0]['id']).to be_an(Integer)
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
		context "Existing treenode with multi level breadcrumb" do
			before :each do
        treenode = create(:grandchild_treenode)
				get :show, api_key: @api_key, id: treenode.id, show_breadcrumb: true
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
		context "Existing treenode with multi level breadcrumb, when requesting breadcrumb as string" do
      before :each do
        @treenode = create(:grandchild_treenode)
      end
      it "should return breadcrumb as string when requested properly" do
				get :show, api_key: @api_key, id: @treenode.id, show_breadcrumb: true, show_breadcrumb_as_string: true
        expect(json['treenode']['breadcrumb']).to eq(@treenode.breadcrumb_as_string)
      end
      it "should return not breadcrumb at all if show_breadcrumb is missing" do
				get :show, api_key: @api_key, id: @treenode.id, show_breadcrumb_as_string: true
        expect(json['treenode']['breadcrumb']).to be_nil
      end
		end
		context "Asking for 'root' node" do
			before :each do
        treenode = create(:top_treenode)
        create_list(:treenode, 10, parent: treenode)
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
    context "Job list pagination" do
      it "should return metadata about pagination" do
        Job.per_page = 2
        treenode = create(:treenode)
        create_list(:job, 3, treenode: treenode)
        get :show, api_key: @api_key, id: treenode.id, show_jobs: true
        expect(json['treenode']['jobs']).to_not be_empty
        expect(json['treenode']['jobs'].count).to eq(2)
        expect(json['treenode']['meta']['query']['total']).to eq(3)
        expect(json['treenode']['meta']['pagination']['pages']).to eq(2)
        expect(json['treenode']['meta']['pagination']['page']).to eq(1)
        expect(json['treenode']['meta']['pagination']['next']).to eq(2)
        expect(json['treenode']['meta']['pagination']['previous']).to eq(nil)
        expect(json['treenode']['meta']['pagination']['per_page']).to eq(2)
      end
      it "should return paginated second page when given page number" do
        Job.per_page = 2
        treenode = create(:treenode)
        create_list(:job, 3, treenode: treenode)
        get :show, api_key: @api_key, id: treenode.id, show_jobs: true, page: 2
        expect(json['treenode']['jobs']).to_not be_empty
        expect(json['treenode']['jobs'].count).to eq(1)
        expect(json['treenode']['meta']['query']['total']).to eq(3)
        expect(json['treenode']['meta']['pagination']['pages']).to eq(2)
        expect(json['treenode']['meta']['pagination']['page']).to eq(2)
        expect(json['treenode']['meta']['pagination']['next']).to eq(nil)
        expect(json['treenode']['meta']['pagination']['previous']).to eq(1)
      end
      it "should return first page when given out of bounds page number" do
        Job.per_page = 2
        treenode = create(:treenode)
        create_list(:job, 3, treenode: treenode)
        get :show, api_key: @api_key, id: treenode.id, show_jobs: true, page: 2000000000
        expect(json['treenode']['jobs']).to_not be_empty
        expect(json['treenode']['jobs'].count).to eq(2)
        expect(json['treenode']['meta']['query']['total']).to eq(3)
        expect(json['treenode']['meta']['pagination']['pages']).to eq(2)
        expect(json['treenode']['meta']['pagination']['page']).to eq(1)
        expect(json['treenode']['meta']['pagination']['next']).to eq(2)
        expect(json['treenode']['meta']['pagination']['previous']).to eq(nil)
      end
    end
	end

  describe "PUT update" do
    context "with valid values" do
      it "should return an updated treenode" do
        treenode = create(:treenode)
        treenode.name = "NewName"
        post :update, api_key: @api_key, id: treenode.id, treenode: treenode.as_json
        expect(json['treenode']).to_not be nil
        expect(json['treenode']['name']).to eq 'NewName'
        expect(response.status).to eq 200
      end
    end
    context "with invalid values" do
      it "should return an error message" do
        treenode = create(:treenode)
        treenode.name = ""
        post :update, api_key: @api_key, id: treenode.id, treenode: treenode.as_json
        expect(json['error']).to_not be nil
        expect(response.status).to eq 422
      end
    end
  end

  describe "DELETE delete" do
    context "an existing treenode" do
      it "should return 200" do
        treenode = create(:treenode)
        delete :destroy, api_key: @api_key, id: treenode.id
        expect(response.status).to eq 200

        treenode2 = Treenode.unscoped.find(treenode.id)
        expect(treenode2.deleted?).to be true
      end
    end
  end
end

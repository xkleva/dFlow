require "rails_helper"

describe Api::ConfigController do
	before :each do
		@api_key = APP_CONFIG["api_key_users"].first["api_key"]
	end

	describe "GET role_list" do
		context "Role exist" do
			it "should return list of roles" do
				get :role_list, api_key: @api_key
				expect(json['config']['roles']).to_not be nil
				expect(json['config']['roles'][0]['name']).to_not be nil
			end
		end
	end

  describe "GET state list" do
    context "States exist" do
      it "should return a list of states" do
        get :state_list, api_key: @api_key
        expect(json['config']['states']).to_not be nil
        expect(json['config']['states'].first).to eq "START"
      end
    end
  end
end

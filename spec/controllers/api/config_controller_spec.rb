require "rails_helper"

describe Api::ConfigController do
	before :each do
		@api_key = APP_CONFIG["api_key"]
	end

	describe "GET role_list" do
		context "Role exist" do
			it "should return list of roles" do
				get :role_list, api_key: @api_key
				expect(json['roles']).to_not be nil
				expect(json['roles'][0]['name']).to_not be nil
			end
		end
		# context "Roles not configured (empty array)" do
		# 	it "should return an error message" do
		# 		APP_CONFIG["user_roles"] = []
		# 		get :role_list, api_key: @api_key
		# 		expect(json['error']).to_not be nil
		# 	end
		# end
		# context "Roles not configured (nil)" do
		# 	it "should return an error message" do
		# 		APP_CONFIG["user_roles"] = nil
		# 		get :role_list, api_key: @api_key
		# 		expect(json['error']).to_not be nil
		# 	end
		# end
	end
end
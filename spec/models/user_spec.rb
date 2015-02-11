require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe User, :type => :model do
	before :each do
		config_init
	end
	
	describe "role_valid" do
		context "role exists in config" do
			it "should not contain an error" do
				user = User.new(username: "hej", name: "svej", role: "ADMIN")
				expect(user.errors.size).to be 0
			end
		end
		context "role does not exist in config" do
			user = User.new(username: "awd", name: "svej", role: "FOO")
			it "should render user object invalid" do
				expect(user.valid?).to be false
				expect(user.errors.size).to_not eq 0
				expect(user.errors.messages[:role]).not_to be nil
			end
		end
	end

	describe "email" do
		context "email is written in wrong format" do
			user = User.new(username: "awd", name: "svej", role: "ADMIN", email: "test@.com")
			it "should invalidate object" do
				expect(user.valid?).to be false
			end
			it "should return an error message for field email" do
				expect(user.errors.messages[:email]).to_not be nil
			end
		end
		context "email is nil" do
			user = User.new(username: "awd", name: "svej", role: "ADMIN", email: nil)
			it "should validate object" do
				expect(user.valid?).to be true
			end
		end
		context "email is written in proper format" do
			user = User.new(username: "awd", name: "svej", role: "ADMIN", email: "test@test.com")
			it "should validate object" do
				expect(user.valid?).to be true
			end
		end
	end

	describe "username" do
		context "username is nil" do
			user = User.new(username: nil, name: "svej", role: "ADMIN", email: "test@test.com")
			it "should invalidate object" do
				expect(user.valid?).to be false
			end
			it "should return an error message for field username" do
				expect(user.errors.messages[:username]).to_not be nil
			end
		end
		context "username is not unique" do
			user = User.new(username: "admin_user", name: "svej", role: "ADMIN", email: "test@test.com")
			it "should invalidate object" do
				expect(user.valid?).to be false
			end
			it "should return an error message for field username" do
				expect(user.errors.messages[:username]).to_not be nil
			end
		end
		context "username is properly formatted and unique" do
			user = User.new(username: "123user456", name: "svej", role: "ADMIN", email: "test@test.com")
			it "should validate object" do
				expect(user.valid?).to be true
			end
		end
	end

	describe "name" do
		context "name is nil" do
			user = User.new(username: "123user456", name: nil, role: "ADMIN", email: "test@test.com")
			it "should invalidate object" do
				expect(user.valid?).to be false
			end
			it "should return an error message for field name" do
				expect(user.errors.messages[:name]).to_not be nil
			end
		end
		context "name is properly formatted" do
			user = User.new(username: "123user456", name: "My Name", role: "ADMIN", email: "test@test.com")
			it "should validate object" do
				expect(user.valid?).to be true
			end
		end
	end

end
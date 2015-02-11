require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe User, :type => :model do
	before :each do
		config_init
	end
	
	describe "role_valid" do
		context "role exists" do
			it "should not contain an error" do
				user = User.new(username: "hej", name: "svej", role: "ADMIN")
				expect(user.errors.size).to be 0
			end
		end
		context "role does not exist" do
			user = User.new(username: "awd", name: "svej", role: "ADMINNN")
			it "should render user object invalid" do
				expect(user.valid?).to be false
				expect(user.errors.size).to_not eq 0
				expect(user.errors.messages[:role]).not_to be nil
			end
		end
	end
end
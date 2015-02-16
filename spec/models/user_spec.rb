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

  describe "user create_missing_users_from_file" do
    context "create from local passwd file" do
      it "should create single user from file" do
        expect(User.find_by_username("admin")).to be_nil
        User.create_missing_users_from_file("#{Rails.root}/spec/support/test-passwd-first")
        user = User.find_by_username("admin")
        expect(user).to_not be_nil
        expect(user.email).to eq("admin@example.com")
        expect(user.name).to eq("Administrator User")
      end

      it "should add more users when loading multiple files" do
        expect(User.find_by_username("admin")).to be_nil
        expect(User.find_by_username("test1")).to be_nil
        expect(User.find_by_username("test2")).to be_nil
        User.create_missing_users_from_file("#{Rails.root}/spec/support/test-passwd-first")
        expect(User.find_by_username("admin")).to_not be_nil
        User.create_missing_users_from_file("#{Rails.root}/spec/support/test-passwd-second")
        expect(User.find_by_username("test1")).to_not be_nil
        expect(User.find_by_username("test2")).to_not be_nil
      end

      it "should not overwrite existing users" do
        user_count = User.count
        expect(User.find_by_username("admin")).to be_nil
        expect(User.find_by_username("test1")).to be_nil
        expect(User.find_by_username("test2")).to be_nil
        expect(User.find_by_username("test3")).to be_nil
        User.create_missing_users_from_file("#{Rails.root}/spec/support/test-passwd-first")
        expect(User.find_by_username("admin")).to_not be_nil
        User.create_missing_users_from_file("#{Rails.root}/spec/support/test-passwd-second")
        expect(User.find_by_username("test1")).to_not be_nil
        expect(User.find_by_username("test2")).to_not be_nil
        User.create_missing_users_from_file("#{Rails.root}/spec/support/test-passwd-third")
        expect(User.find_by_username("test3")).to_not be_nil

        expect(User.count).to eq(user_count+4)

        user = User.find_by_username("admin")
        expect(user.email).to eq("admin@example.com")
        expect(user.name).to eq("Administrator User")

        user = User.find_by_username("test3")
        expect(user.email).to eq("test3@example.com")
        expect(user.name).to eq("Test3 User")
      end
    end

    context "for missing passwd file" do
      it "should do nothing" do
        user_count = User.count
        User.create_missing_users_from_file("#{Rails.root}/spec/support/no-such-file-passwd")
        expect(User.count).to eq(user_count)
      end
    end
  end

  describe "role_object" do
    context "for a valid role" do
      it "should return a hash object" do
        user = User.find_by_username("admin_user")
        expect(user.role_object).to be_a(Hash)
        expect(user.role_object[:name]).to eq "ADMIN"
        expect(user.role_object[:rights]).to_not be nil
      end
    end
  end

  describe "has_right?" do
    context "user has right" do
      it "should return true" do
        user = User.find_by_username("admin_user")
        expect(user.has_right?("manage_users")).to be true
      end
    end
  end
end


require 'rails_helper'

RSpec.describe User, :type => :model do

  describe "role" do
    it {should validate_inclusion_of(:role).in_array(APP_CONFIG["user_roles"].map{|x| x["name"]})}
    it {should validate_presence_of(:role)}
  end

  describe "email" do
    it {should allow_value(nil).for(:email)}
    it {should allow_value('test@test.com').for(:email)}
    it {should_not allow_value('test@.com').for(:email)}
  end

  describe "username" do
    it {should validate_presence_of(:username)}
    it {should validate_uniqueness_of(:username).case_insensitive.scoped_to(:deleted_at)}
    
  end

  describe "name" do
    it {should validate_presence_of(:name)}
  end

  describe "deleted_at" do
    it {should allow_value(nil).for(:deleted_at)}
    it {should allow_value(Time.now).for(:deleted_at)}
  end

  describe "deleted?" do
    context "deleted_at is set" do
      it "should return true" do
        user = create(:deleted_user)
        expect(user.deleted?).to be_truthy
      end
    end
    context "deleted_at is nil" do
      it "should return false" do
        user = create(:user)
        expect(user.deleted?).to be_falsy
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
        user = build(:admin_user)
        expect(user.role_object).to be_a(Hash)
        expect(user.role_object["name"]).to eq "ADMIN"
        expect(user.role_object["rights"]).to_not be nil
      end
    end
  end

  describe "has_right?" do
    context "user has right" do
      it "should return true" do
        user = build(:admin_user)
        expect(user.has_right?("manage_users")).to be true
      end
    end
  end
end


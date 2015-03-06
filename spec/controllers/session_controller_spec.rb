require 'rails_helper'

RSpec.describe SessionController, :type => :controller do
  before :each do
    WebMock.disable_net_connect!
    # Load user with username "admin" and password "admin"
    passwd_file = "#{Rails.root}/spec/support/test-passwd-first"
    User.create_missing_users_from_file(passwd_file)
    Rails.cache.write("test_passwd_filename", passwd_file)
  end
  after :each do
    WebMock.allow_net_connect!
  end

  describe "create session" do
     it "should return access_token on valid credentials" do
      post :create, username: "admin", password: "admin"
      user = User.find_by_username("admin")
      expect(json['access_token']).to be_truthy
      expect(json['token_type']).to eq("bearer")
      expect(json['access_token']).to eq(user.access_tokens.first.token)
    end

    it "should return 401 with error on invalid password and invalid user" do
      post :create, username: "invalid_user", password: "invalid_password"
      expect(response.status).to eq(401)
      expect(json['error']).to be_truthy
    end

    it "should return 401 with error on invalid password for valid user" do
      post :create, username: "admin", password: "invalid_password"
      expect(response.status).to eq(401)
      expect(json['error']).to be_truthy
    end

    it "should return user data on valid credentials" do
      post :create, username: "admin", password: "admin"
      user = User.find_by_username("admin")
      expect(json['user']['name']).to eq(user.name)
    end

    it "should allow the same user to login multiple times, getting different tokens" do
      post :create, username: "admin", password: "admin"
      token1 = json['access_token']
      post :create, username: "admin", password: "admin"
      token2 = json['access_token']
      get :show, id: token1
      expect(response.status).to eq(200)
      get :show, id: token2
      expect(response.status).to eq(200)
    end
  end

  describe "create session for external user" do
    before :each do
      User.create(username: 'fake_external_user', name: 'Fake User', email: 'fake.user@example.com', role: "OPERATOR")

      stub_request(:get, APP_CONFIG["external_auth_url"]+"/fake_external_user")
        .with(query: {password: "fake_valid_password"})
        .to_return(body: {auth: {yesno: true }}.to_json)

      stub_request(:get, APP_CONFIG["external_auth_url"]+"/fake_external_user")
        .with(query: {password: "fake_invalid_password"})
        .to_return(body: {auth: {yesno: false }}.to_json)
    end

    it "should return access_token for valid external user credentials" do
      post :create, username: "fake_external_user", password: "fake_valid_password"
      user = User.find_by_username("fake_external_user")
      expect(json['access_token']).to be_truthy
      expect(json['token_type']).to eq("bearer")
      expect(json['access_token']).to eq(user.access_tokens.first.token)
    end

    it "should return 401 with error on invalid external user credentials" do
      post :create, username: "fake_external_user", password: "fake_invalid_password"
      expect(response.status).to eq(401)
      expect(json['error']).to be_truthy
    end
  end
  
  describe "validate session" do
    it "should return ok on valid session and extend expire time" do
      post :create, username: "admin", password: "admin"
      token = json['access_token']
      token_object = AccessToken.find_by_token(token)
      first_expire = token_object.token_expire
      get :show, id: token
      expect(json['access_token']).to eq(token)
      token_object = AccessToken.find_by_token(token)
      second_expire = token_object.token_expire
      expect(first_expire).to_not eq(second_expire)
    end

    it "should return 401 on invalid session and clear token" do
      post :create, username: "admin", password: "admin"
      token = json['access_token']
      token_object = AccessToken.find_by_token(token)
      token_object.update_attribute(:token_expire, Time.now - 1.day)
      get :show, id: token
      expect(response.status).to eq(401)
      expect(json).to have_key("error")
    end

    it "should return user data on valid session" do
      post :create, username: "admin", password: "admin"
      user = User.find_by_username("admin")
      get :show, id: json['access_token']
      expect(json['user']['name']).to eq(user.name)
    end
  end
end

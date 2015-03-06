require 'rails_helper'

RSpec.configure do |c|
  c.include ModelHelper
end

RSpec.describe JobActivity, :type => :model do
  before :each do
    config_init
  end

  describe "event" do
    it {should validate_inclusion_of(:event).in_array(APP_CONFIG["events"].map {|x| x["name"]})}
  end

  describe "job" do
    it {should belong_to(:job)}
  end

  describe "username" do
    it {should validate_presence_of(:username)}
  end

  describe "message" do
    it {should_not validate_presence_of(:message)}
    it {should allow_value(nil).for(:message)}
  end
end

require 'rails_helper'

RSpec.describe JobActivity, :type => :model do

  describe "event" do
    it {should validate_inclusion_of(:event).in_array(SYSTEM_DATA["events"].map {|x| x["name"]})}
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

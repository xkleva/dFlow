require 'rails_helper'

RSpec.describe AccessToken, :type => :model do

  describe "user" do
    it {should validate_presence_of(:user_id)}
  end

end

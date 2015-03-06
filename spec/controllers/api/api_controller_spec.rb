require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

describe Api::ApiController, :type => :controller do
	before :each do
		config_init
		@api_key = APP_CONFIG["api_key"]
	end

end

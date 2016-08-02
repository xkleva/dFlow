require 'rails_helper'

RSpec.describe AssetsController, :type => :controller do
  before :each do
    WebMock.disable_net_connect!
    @api_key = APP_CONFIG["api_key_users"].first["api_key"]
    create(:job, id: 1)
    create(:job, id: 9999)
  end

  after :each do
    WebMock.allow_net_connect!
  end

  describe "job pdf" do
    it "should return pdf data when requesting existing job pdf" do
      #get :job_pdf, asset_id: 1, format: :pdf, api_key: @api_key
      #expect(response.body).to eq("PACKAGING PDF")
      #expect(response.status).to eq(200)
    end

    it "should give error when requesting existing job pdf" do
      #get :job_pdf, asset_id: 9999, format: :pdf, api_key: @api_key
      #expect(response.status).to eq(404)
    end
  end
end

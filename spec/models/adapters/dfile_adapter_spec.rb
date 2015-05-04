require 'rails_helper'

RSpec.describe DfileAdapter do
  before :each do
    WebMock.disable_net_connect!
    @dfile = DfileAdapter.new(base_url: APP_CONFIG['dfile_base_url'])

    stub_request(:get, /http:\/\/dfile\.example\.org\/download_file\.json\?api_key=test_key&source_file=STORE:\/.+\/existing_file\.txt/).
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, /http:\/\/dfile\.example\.org\/download_file\.json\?api_key=test_key&source_file=STORE:\/.+\/non_existing_file\.txt/).
      to_return(:status => 404, :body => "", :headers => {})
  end

  after :each do
    WebMock.allow_net_connect!
  end

  describe "file_exists" do
    it "should return true when file exists" do 
      file_status = @dfile.file_exists?("STORE", "/12345/existing_file.txt")
      expect(file_status).to be_truthy
    end

    it "should return false when file does not exists" do 
      file_status = @dfile.file_exists?("STORE", "/12345/non_existing_file.txt")
      expect(file_status).to be_falsey
    end
  end
end

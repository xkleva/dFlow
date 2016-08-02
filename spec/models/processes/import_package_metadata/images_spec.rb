require 'webmock/rspec'
#Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }
#Dir[Rails.root.join("app/models/helpers/*.rb")].each { |f| require f }

describe ImportPackageMetadata::Images do
  before :all do
    @dfile_api_key = "test_key"
    WebMock.disable_net_connect!
  end

  after :all do
    WebMock.allow_net_connect!
  end

  describe "fetch_page_count" do

    context "for an existing job" do
      it "should set page_count accordingly" do
        stub_request(:get, "http://dfile.example.org/download_file?api_key=test_key&source_file=PACKAGING:/1/page_count/1.txt").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "10", :headers => {})

        job = create(:job, id: 1)
        images = ImportPackageMetadata::Images.new(job: job)
        images.fetch_page_count

        expect(images.page_count).to eq 10
      end
    end
  end

  describe "fetch_images" do
    context "for 10 images" do
      it "should create 10 image objects" do
        stub_request(:get, "http://dfile.example.org/download_file?api_key=test_key&source_file=PACKAGING:/1/page_metadata/0001.xml").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.open(Rails.root + 'spec/models/processes/import_package_metadata/stubs/0001.xml').read, :headers => {})

        job = create(:job, id: 1)
        images = ImportPackageMetadata::Images.new(job: job)
        images.page_count = 10
        images.fetch_images
        expect(images.images.count).to eq 10
      end
    end
  end

    
end

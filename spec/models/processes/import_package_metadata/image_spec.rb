#require 'webmock'
require 'webmock/rspec'
require 'rails_helper'
#Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }

describe ImportPackageMetadata::Image do
  before :all do
    WebMock.disable_net_connect!
    @dfile_api_key = "test_key"
  end

  after :all do
     WebMock.allow_net_connect!
  end

  describe "map_physical" do

    context "a number that is not mapped" do
      it "should raise StandardError" do
        image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 1, source: 'libris')
        expect{image.map_physical(physical_numeric: 0)}.to raise_error StandardError
      end
    end

    context "a number that is mapped" do
      it "should not raise StandardError" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 1, source: 'libris')
        expect{image.map_physical(physical_numeric: 1)}.not_to raise_error
      end
    end

    context "The number for cover for image num 1" do
      it "should return text FrontCoverOutside" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 1, source: 'libris')
        expect(image.map_physical(physical_numeric: 4)).to eq 'FrontCoverOutside'
      end
    end

    context "The number for cover for image num 2" do
      it "should return text FrontCoverInside" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 2, source: 'libris')
        expect(image.map_physical(physical_numeric: 4)).to eq 'FrontCoverInside'
      end
    end

    context "The number for cover for image num 3" do
      it "should raise error" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 3, source: 'libris')
        expect{image.map_physical(physical_numeric: 4)}.to raise_error StandardError
      end
    end

    context "The number for cover for second to last image" do
      it "should return text BackCoverInside" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 9, source: 'libris')
        expect(image.map_physical(physical_numeric: 4)).to eq 'BackCoverInside'
      end
    end

    context "The number for cover for last image" do
      it "should return text BackCoverOutside" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 10, source: 'libris')
        expect(image.map_physical(physical_numeric: 4)).to eq 'BackCoverOutside'
      end
    end

    context "The number for leftPage" do
      it "should return text LeftPage" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 2, source: 'libris')
        expect(image.map_physical(physical_numeric: 1)).to eq 'LeftPage'
      end
    end
  end

  describe "map_logical" do

    context "for an invalid mapping number" do
      it "should return string 'Undefined'" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 2, source: 'libris')
        expect(image.map_logical(logical_numeric: 0)).to eq 'Undefined'
      end
    end

    context "for a valid mapping number" do
      it "should return corresponding string" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: nil, image_count: 10, image_num: 2, source: 'libris')
        expect(image.map_logical(logical_numeric: 4)).to eq 'TitlePage'
      end
    end
  end

  describe "validate_group_name" do
    
    context "for a nonexisting group_name" do
      it "should raise exception" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: [], image_count: 10, image_num: 3, source: 'libris')
        expect{image.validate_group_name(group_name: "test")}.to raise_error StandardError
      end
    end

    context "for an existing group_name" do
      it "should return true" do
          image = ImportPackageMetadata::Image.new(job_id: 1, group_names: ["groupName1", "groupName2"], image_count: 10, image_num: 3, source: 'libris')
        expect(image.validate_group_name(group_name: "groupName2")).to be_truthy
      end
    end
  end

  describe "fetch_metadata" do

    context "for an image with type LeftPage and content TitlePage" do
      it "should set physical to 'LeftPage' and logical to 'TitlePage'" do

        stub_request(:get, "http://dfile.example.org/download_file?api_key=test_key&source_file=PACKAGING:/1/page_metadata/0003.xml").
                   with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
                            to_return(:status => 200, :body => File.new('spec/models/processes/import_package_metadata/stubs/0003.xml'), :headers => {})

        image = ImportPackageMetadata::Image.new(job_id: 1, group_names: [], image_count: 10, image_num: 3, source: 'libris')

        image.fetch_metadata

        expect(image.physical).to eq 'LeftPage'
        expect(image.logical).to eq 'TitlePage'
      end
    end
    
    context "for an image without page type" do
      it "should invalidate object" do

        stub_request(:get, "http://dfile.example.org/download_file?api_key=test_key&source_file=PACKAGING:/999/page_metadata/0001.xml").
                   with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
                            to_return(:status => 200, :body => File.new('spec/models/processes/import_package_metadata/stubs/no-data.xml'), :headers => {})

        image = ImportPackageMetadata::Image.new(job_id: 999, group_names: [], image_count: 10, image_num: 1, source: 'libris')

        expect{image.fetch_metadata}.to raise_error StandardError
      end
    end

    context "for an image without page type and no force physical setting" do
      before :each do
        APP_CONFIG['queue_manager']['processes']['import_metadata']['require_physical'] = false
      end
      after :each do
        APP_CONFIG['queue_manager']['processes']['import_metadata']['require_physical'] = true
      end
      it "should validate object" do

        stub_request(:get, 'http://dfile.example.org'+'/download_file')
        .with(query: {source_file: "PACKAGING:/999/page_metadata/0001.xml", api_key: @dfile_api_key})
        .to_return(:body => File.new('spec/models/processes/import_package_metadata/stubs/no-data.xml'), :status => 200)

        image = ImportPackageMetadata::Image.new(job_id: 999, group_names: [], image_count: 10, image_num: 1, source: 'libris')

        expect{image.fetch_metadata}.not_to raise_error
      end
    end
  end

  describe "run" do

    context "for a valid image" do
      it "should return a valid object" do
        stub_request(:get, 'http://dfile.example.org'+'/download_file')
        .with(query: {source_file: "PACKAGING:/1/page_metadata/0003.xml", api_key: @dfile_api_key})
        .to_return(:body => File.new('spec/models/processes/import_package_metadata/stubs/0003.xml'), :status => 200)

        image = ImportPackageMetadata::Image.new(job_id: 1, group_names: [], image_count: 10, image_num: 3, source: 'libris')

        image.run

        expect(image.physical).to eq 'LeftPage'
        expect(image.logical).to eq 'TitlePage'
      end
    end

    context "for an invalid message" do
      it "should raise an error" do
        stub_request(:get, 'http://dfile.example.org'+'/download_file')
        .with(query: {source_file: "PACKAGING:/999/page_metadata/0001.xml", api_key: @dfile_api_key})
        .to_return(:body => File.new('spec/models/processes/import_package_metadata/stubs/no-data.xml'), :status => 200)

        image = ImportPackageMetadata::Image.new(job_id: 999, group_names: [], image_count: 10, image_num: 1, source: 'libris')

        expect{image.run}.not_to raise_error
        expect(image.error[:code]).not_to be nil
      end
    end
  end
end

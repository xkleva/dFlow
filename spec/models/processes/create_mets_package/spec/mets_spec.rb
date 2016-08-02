
require 'rails_helper'

describe CreateMetsPackage::METS do
  before :all do
    WebMock.disable_net_connect!

    # Stubs
    
    # Stub list of master files according to file
    stub_request(:get, "http://dfile.example.org/list_files?api_key=test_key&ext=tif&show_catalogues=true&source_dir=PACKAGING:/1001006/master").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => File.open("spec/models/processes/create_mets_package/spec/fixtures/stubs/1001006_list_files_master.json"), :headers => {'Content-Type' => 'application/json'})

    # Stub list of web files according to file
    stub_request(:get, "http://dfile.example.org/list_files?api_key=test_key&ext=jpg&show_catalogues=true&source_dir=PACKAGING:/1001006/web").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => File.open("spec/models/processes/create_mets_package/spec/fixtures/stubs/1001006_list_files_web.json"), :headers => {'Content-Type' => 'application/json'})
    
    # Stub list of web files according to xml
    stub_request(:get, "http://dfile.example.org/list_files?api_key=test_key&ext=xml&show_catalogues=true&source_dir=PACKAGING:/1001006/alto").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => File.open("spec/models/processes/create_mets_package/spec/fixtures/stubs/1001006_list_files_alto.json"), :headers => {'Content-Type' => 'application/json'})

    # Stub list of pdf files according to xml
    stub_request(:get, "http://dfile.example.org/list_files?api_key=test_key&ext=pdf&show_catalogues=true&source_dir=PACKAGING:/1001006/pdf").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => File.open("spec/models/processes/create_mets_package/spec/fixtures/stubs/1001006_list_files_pdf.json"), :headers => {'Content-Type' => 'application/json'})

    # Stub chekcsum requests to process 123
    stub_request(:get, /http:\/\/dfile\.example.org\/checksum\?api_key=test_key&source_file=PACKAGING:\/1001006\/(web|master|alto|pdf)\/\w+.(tif|jpg|xml|pdf)/).with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => '{"id": "123"}', :headers => {'Content-Type' => 'application/json'})

    # stub move file
    stub_request(:get, "http://dfile.example.org/move_file?api_key=test_key&dest_file=PACKAGING:/1001006/pdf/GUB1001006.pdf&source_file=PACKAGING:/1001006/pdf/GUB01001006.pdf").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200, :body => "", :headers => {})

    @redis = Redis.new(db: APP_CONFIG['redis_db']['db'], host: APP_CONFIG['redis_db']['host'])

    # Set checksum result value for process 123
    @redis.set('dFile:processes:123:state:done', "123")
    @redis.set('dFile:processes:123:value', "df9790310fb3875ab66e05b06be5d445df0f6634f1a08c04e33130d9c9488c902687a15761e45891eb34963c42c92a3cf92c964454c665acfadc330bcb387f23")
    
    @dfile_api_key = "test_key"

    @xml_job = JSON.parse(File.new('spec/models/processes/create_mets_package/spec/fixtures/1001006.json', 'r:utf-8').read)['job']
    @job = create(:job, id: 1001006, package_metadata: @xml_job['package_metadata'].to_json, xml: @xml_job['xml'], copyright: true)
    @mets = CreateMetsPackage::METS.new(job: @job)
    # puts @mets.mets_xml
  end


  after :all do
    WebMock.allow_net_connect!
  end

  describe "mets sections" do
    context "head" do
      it "should check for relevant information in header" do
        expect(@mets.head).to include("mets:metsHdr")
        expect(@mets.head).to include(CreateMetsPackage::METS_CONFIG['CREATOR']['name'])
        expect(@mets.head).to match(CreateMetsPackage::METS_CONFIG['CREATOR']['sigel'])
        expect(@mets.head).to match(CreateMetsPackage::METS_CONFIG['ARCHIVIST']['name'])
        expect(@mets.head).to match(CreateMetsPackage::METS_CONFIG['ARCHIVIST']['sigel'])
      end
    end

    context "administrative" do
      it "should check for relevant information in administrative" do
        expect(@mets.administrative).to include("mets:amdSec")
        expect(@mets.administrative).to include(CreateMetsPackage::METS_CONFIG['COPYRIGHT_STATUS']['true'])
        expect(@mets.administrative).to match(CreateMetsPackage::METS_CONFIG['PUBLICATION_STATUS']['true'])
      end
    end

    context "bibliographic" do
      it "should check for relevant information in bibliographic" do
        expect(@mets.bibliographic).to include("mets:dmdSec")
        #expect(@mets.bibliographic).to include("2015-04-22T15:19:33")
        expect(@mets.bibliographic).to include("MODS")
      end
    end

  end
end

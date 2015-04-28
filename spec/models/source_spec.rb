require 'rails_helper'

RSpec.describe Source, :type => :model do
  before :each do
    #config_init
    WebMock.disable_net_connect!
    @libris = Source.find_by_name('libris')
    @document = Source.find_by_name('document')
    @letter = Source.find_by_name('letter')

    ## Stub request for getting source data
    stub_request(:get, "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:1234").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(
        :status => 200,
        :body => File.new("#{Rails.root}/spec/support/sources/libris-xsearch-response-onr1234.xml"),
        :headers => {"Content-Type" => "text/xml;charset=UTF-8"})

    ## Stub request for getting source data
    stub_request(:get, "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:1").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(
        :status => 200,
        :body => File.new("#{Rails.root}/spec/support/sources/libris-xsearch-response-onr1.xml"),
        :headers => {"Content-Type" => "text/xml;charset=UTF-8"})

    stub_request(:get, "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:1").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/libris-1-mock.xml"), :headers => {})

    stub_request(:get, "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:1234").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/libris-1234-mock.xml"), :headers => {})

    stub_request(:get, "http://www.ub.gu.se/handskriftsdatabasen/api/getdocument.xml?id=1697").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/document-1697-mock.xml"), :headers => {})

    stub_request(:get, "http://www.ub.gu.se/handskriftsdatabasen/api/getdocument.xml?id=99999999999").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/document-99999999999-mock.xml"), :headers => {})

    stub_request(:get, "http://www.ub.gu.se/handskriftsdatabasen/api/getletter.xml?id=29149").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/letter-29149-mock.xml"), :headers => {})

    stub_request(:get, "http://www.ub.gu.se/handskriftsdatabasen/api/getletter.xml?id=99999999999").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/letter-99999999999-mock.xml"), :headers => {})
  end
  after :each do
    WebMock.allow_net_connect!
  end

  describe "fetch source data" do
    context "with an existing libris ID" do
      it "should return a hash with values" do
        data = @libris.fetch_source_data(1234)
        expect(data[:title]).to start_with("Water")
        expect(data[:metadata][:type_of_record]).to eq("am")
      end
    end
    context "with a non-existing libris ID" do
      it "should return an empty object" do
        data = @libris.fetch_source_data(1)
        expect(data.empty?).to be true
      end
    end

    context "with an existing document ID" do
      it "should return a hash with values" do
        data = @document.fetch_source_data(1697)
        expect(data[:title]).to eq("Fotografier och negativ")
        expect(data[:metadata][:type_of_record]).to eq("tm")
      end
    end
    context "with a non-existing document ID" do
      it "should return an empty object" do
        data = @document.fetch_source_data(99999999999)
        expect(data.empty?).to be true
      end
    end

    context "with an existing letter ID" do
      it "should return a hash with values" do
        data = @letter.fetch_source_data(29149)
        expect(data[:title]).to match("Gustaf Henrik Brusewitz")
        expect(data[:title]).to match("Carl August Rydberg")
        expect(data[:metadata][:type_of_record]).to eq("tm")
      end
    end
    context "with a non-existing document ID" do
      it "should return an empty object" do
        data = @letter.fetch_source_data(99999999999)
        expect(data.empty?).to be true
      end
    end
  end

  describe "find by name" do
    context "when source is available" do
      it "should find a class" do
        my_source = Source.find_by_name('libris')
        expect(my_source).not_to be nil
        expect(my_source).to be Libris
      end
    end
    context "when using a nonsense source name" do
      it "should return error" do
        my_source = Source.find_by_name('tjottabengtson')
        expect(my_source).to be nil
      end
    end
  end

end

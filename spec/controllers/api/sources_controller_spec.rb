require 'rails_helper'

describe Api::SourcesController do
  before :each do
    WebMock.disable_net_connect!
    @api_key = APP_CONFIG["api_key"]
    @libris_source = Source.find_by_class_name("Libris")

    # Request för att hämta en post som inte finns (id 0), dvs ett xsearch-svar utan record i.
    stub_request(:get, "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:0").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/libris-invalid-entry-onr0.xml"), :headers => {})

    # Request för att hämta en post som finns (id: 12345), dvs xsearch-svar somm innehåller ett record.
    stub_request(:get, "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:12345").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => File.new("#{Rails.root}/spec/support/sources/libris-valid-entry-onr12345.xml"), :headers => {"Content-Type" => "text/xml;charset=UTF-8"})
  end
  after :each do
    WebMock.allow_net_connect!
  end

#########
  # describe "GET validate_new_objects" do
  #   context "one object with valid data" do
  #     it "should return success message and source id" do
  #       data = [{source_name: "Libris", catalog_id: 1234}]
  #       get :validate_new_objects, api_key: @api_key, objects: data
  #       expect(json['error']).to be nil
  #       expect(json['data']['catalog_ids'].size).to eq(1)
  #       expect(json['data']['objects'][0]['source_id']).to eq(@libris_source.id)
  #     end
  #   end
  #   context "objects are empty" do
  #     it "should return error" do
  #       data = []
  #       get :validate_new_objects, api_key: @api_key, objects: data
  #       expect(json['error']).not_to be nil
  #     end
  #     it "should return error with error code REQUEST_ERROR" do
  #       data = []
  #       get :validate_new_objects, api_key: @api_key, objects: data
  #       expect(json['error']['code']).to eq('REQUEST_ERROR')
  #       expect(json['error']['msg']).to eq('No valid objects are given')
  #     end
  #   end
  #   context "four objects with valid data and two catalog_ids" do
  #     it "should return success message and source ids" do
  #       data = [{source_name: "Libris", catalog_id: 1234, name: "First"},
  #         {source_name: "Libris", catalog_id: 1234, name: "Second"},
  #         {source_name: "Libris", catalog_id: 1235, name: "Third"},
  #         {source_name: "Libris", catalog_id: 1235, name: "Fourth"}]
  #       get :validate_new_objects, api_key: @api_key, objects: data
  #       expect(json['error']).to be nil
  #       expect(json['data']['catalog_ids'].size).to eq(2)
  #       expect(json['data']['objects'][0]['source_id']).to eq(@libris_source.id)
  #     end
  #   end
  #   context "one object with an invalid source" do
  #     it "should return an error message" do
  #       data = [{source_name: "Libriss", catalog_id: 1234}]
  #       get :validate_new_objects, api_key: @api_key, objects: data
  #       expect(json['error']).to_not be nil
  #     end
  #   end
  #   context "one object with invalid fields" do
  #     it "should return an error message" do
  #       data = [{source_name: "Libris", catalog_id: 1234, wrongcolumn: "testing"}]
  #       get :validate_new_objects, api_key: @api_key, objects: data
  #       expect(json['error']).to_not be nil
  #     end
  #   end
  # end
  # describe "GET fetch_source_data" do
  #   context "with invalid attributes" do
  #     it "returns a json error message" do
  #       get :fetch_source_data, api_key: @api_key, catalog_id: 1, source: 'libris'
  #       expect(json['error']).to_not be nil
  #       expect(json['data']).to be nil
  #     end
  #   end
  #   context "with valid attributes" do
  #     it "Returns object data" do
  #       get :fetch_source_data, api_key: @api_key, catalog_id: 1234, source: 'libris'
  #       expect(json['error']).to be nil
  #       expect(json['data']['catalog_id']).to eq('1234')
  #     end
  #   end
  #   context "from no valid source" do
  #     it "should return error" do
  #       get :fetch_source_data, api_key: @api_key, catalog_id: 1234, source: 'librisddd'
  #       expect(json['error']).not_to be nil
  #     end
  #     it "should return error with error code OBJECT_ERROR" do
  #       get :fetch_source_data, api_key: @api_key, catalog_id: 1234, source: 'librisddd'
  #       expect(json['error']['code']).to eq('OBJECT_ERROR')
  #       expect(json['error']['msg']).to eq("Could not find a source with id 0")
  #     end
  #   end
  # end
#########

  describe "Get a list of sources" do
    context "there is at least one source available" do
      it "should return json with available sources" do
        get :index, api_key: @api_key
        expect(json['sources']).not_to be nil
      end
    end
    context "there is a specific known source in config" do
      it "should return json of known source" do
        get :index, api_key: @api_key
        expect(json['sources'][0]['class_name']).to eq('Libris')
      end
    end
  end

  describe "Get data from a source" do
    context "the source is available and source id is valid" do
      it "should return json with source data" do
        get :fetch_source_data, api_key: @api_key, id: 12345, name: 'libris'
        expect(json['error']).to be nil
        expect(json['source']['catalog_id']).to eq('12345')
      end
    end

    context "the source is not available" do
      it "should return json with error data" do
        source_name = 'tjottabengtsson'
        get :fetch_source_data, api_key: @api_key, id: 12345, name: source_name
        expect(json['error']).not_to be nil
        expect(json['error']['msg']).to eq("Could not find a source with name #{source_name}")
      end
    end

    context "the source is known and available but source data is empty" do
      it "should return json with error data" do
        source_name = 'libris'
        catalog_id = '0'
        get :fetch_source_data, api_key: @api_key, id: catalog_id, name: source_name
        expect(json['error']).not_to be nil
        expect(json['error']['msg']).to eq("Could not find source data for source: #{source_name} and catalog_id: #{catalog_id}")
      end
    end
  end

  describe "Get data from a manual source" do
    context "the source is available" do
      it "should return json with source data" do
        title = 'My title'
        dc = {
          title: title,
          creator: 'The Creator',
          subject: 'The Subject',
          description: 'The Description',
          publisher: 'The Publisher',
          contributor: 'The Contributor',
          date: 'The Date',
          type: 'The Type',
          format: 'The Format',
          identifier: 'The Identifier',
          source: 'The Source',
          language: 'The Language',
          relation: 'The Relation',
          coverage: 'The Coverage',
          rights: 'The Rights'
        }
        get :fetch_source_data, api_key: @api_key, id: '',
        name: 'dc', dc_title: dc[:title], dc_creator: dc[:creator], dc_subject: dc[:subject], dc_description: dc[:description],
        dc_publisher: dc[:publisher], dc_contributor: dc[:contributor], dc_date: dc[:date], dc_type: dc[:type], dc_format: dc[:format], dc_identifier: dc[:identifier],
        dc_source: dc[:source], dc_language: dc[:language], dc_relation: dc[:relation], dc_coverage: dc[:coverage], dc_rights: dc[:rights]
        pp "-------------------"
        pp json
        pp "-------------------"
        expect(json['error']).to be nil
        expect(json['source']['catalog_id']).to start_with('dc:')
        expect(json['source']['source_name']).to eq('dc')
        expect(json['source']['title']).to eq(title)
        expect(json['source']['metadata']['dc_title']).to eq(title)
      end
    end
  end

end

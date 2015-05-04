# -*- coding: utf-8 -*-
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
        get :fetch_source_data, api_key: @api_key, catalog_id: 12345, name: 'libris'
        expect(json['error']).to be nil
        expect(json['source']['catalog_id']).to eq('12345')
      end
    end

    context "the source is not available" do
      it "should return json with error data" do
        source_name = 'tjottabengtsson'
        get :fetch_source_data, api_key: @api_key, catalog_id: 12345, name: source_name
        expect(json['error']).not_to be nil
        expect(json['error']['msg']).to eq("Could not find a source with name #{source_name}")
      end
    end

    context "the source is known and available but source data is empty" do
      it "should return json with error data" do
        source_name = 'libris'
        catalog_id = '0'
        get :fetch_source_data, api_key: @api_key, catalog_id: catalog_id, name: source_name
        expect(json['error']).not_to be nil
        expect(json['error']['msg']).to eq("Could not find source data for source: #{source_name} and catalog_id: #{catalog_id}")
      end
    end

    context "the source is known and available but required fields are wrong" do
      it "should return json with error data" do
        source_name = 'libris'
        get :fetch_source_data, api_key: @api_key, catalog_id: nil, name: source_name
        expect(response.status).to eq(422)
        expect(json['error']).not_to be nil
        expect(json['error']['code']).to eq("VALIDATION_ERROR")
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
        get :fetch_source_data, api_key: @api_key, name: 'dc', dc: dc
        expect(json['error']).to be nil
        expect(json['source']['catalog_id']).to start_with('dc:')
        expect(json['source']['source_name']).to eq('dc')
        expect(json['source']['title']).to eq(title)
        expect(json['source']['metadata']['dc']['title']).to eq(title)
        expect(json['source']['metadata']['dc']['publisher']).to eq(dc[:publisher])
        expect(json['source']['metadata']['dc']['contributor']).to eq(dc[:contributor])
        expect(json['source']['metadata']['dc']['language']).to eq(dc[:language])
      end
    end
  end

end

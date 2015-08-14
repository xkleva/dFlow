require 'rails_helper'

RSpec.describe DublinCore, :type => :model do

  before :each do
    @dublin_core = Source.find_by_name('dc')
    @ns_prefix = 'dc'
  end

  dc_data = {
    title: 'The Title',
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

  describe "find the source" do
    context "when correctly configured" do
      it "should find a class for the source" do
        my_source = Source.find_by_name('dc')
        expect(my_source).not_to be nil
        expect(my_source).to be DublinCore
      end
    end
  end

  describe "fetch source data" do
    context "when dc data is provided" do
      it "should generate a catalog_id with the format dc:<uuid>" do
        data = @dublin_core.fetch_source_data('dc', dc_data)
        expect(data[:catalog_id]).to start_with("dc:")
      end
      it "should find the title in title" do
        data = @dublin_core.fetch_source_data('dc', dc_data)
        expect(data[:title]).to start_with("The Title")
      end
      it "should find the creator in author" do
        data = @dublin_core.fetch_source_data('dc', dc_data)
        expect(data[:author]).to start_with("The Creator")
      end
      it "should find the title in metadata" do
        data = @dublin_core.fetch_source_data('dc', dc_data)
        expect(data[:metadata][:dc][:title]).to start_with("The Title")
      end
      it "should find the creator in metadata" do
        data = @dublin_core.fetch_source_data('dc', dc_data)
        expect(data[:metadata][:dc][:creator]).to start_with("The Creator")
      end
      it "should find the subject in metadata" do
        data = @dublin_core.fetch_source_data('dc', dc_data)
        expect(data[:metadata][:dc][:subject]).to start_with("The Subject")
      end
    end
  end

  describe "build_xml" do
    context "when fed with correct dublin core metadata" do
      it "should return correct xml" do
        xml = @dublin_core.build_xml(dc_data)
        doc = Nokogiri::XML(xml)
        expect(doc.search("//#{@ns_prefix}:title").text).to start_with("The Title")
      end
    end

    context "when validated agains an xml schema" do
      it "should have a simpledc element as root element" do
        xml = @dublin_core.build_xml(dc_data)
        #schema = Nokogiri::XML::Schema(File.read("/Users/xanjoo/Workspaces/wsjeemars/MyXMLFiles/src/dc-qualified/gub-simple-dc-20150812.xsd"))
        schema = Nokogiri::XML::Schema(open("http://www.ub.gu.se/xml-schemas/simple-dc/v1/gub-simple-dc-20150812.xsd"))
        doc = Nokogiri::XML(xml)

        errors = schema.validate(doc)

        if !errors.empty?
          pp "The XML does not follow the rules in XML Schema:"
          errors.each do |error|
            pp "Validation error: #{error.message}"
          end
        end

        expect(errors).to be_empty
      end
    end
  end

end

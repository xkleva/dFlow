require 'rails_helper'

RSpec.describe DublinCoreXML, :type => :model do

  before :each do
    @dcxml = Source.find_by_name('dcxml')
  end

  xml_data_complex = <<-END.gsub(/^ {6}/, '')
    <record>
      <header>
        <identifier>oai:gupea.ub.gu.se:2077/24</identifier>
        <datestamp>2013-04-23T09:43:42Z</datestamp>
        <setSpec>hdl_2077_21</setSpec>
      </header>
      <metadata>
        <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
        <dc:title>The Title is the title is the title</dc:title>
        <dc:creator>The Creator, Curt</dc:creator>
        <dc:description>This paper deals with...</dc:description>
        <dc:date>2005-04-26T12:02:50Z</dc:date>
        <dc:date>2005-04-26T12:02:50Z</dc:date>
        <dc:date>2003-11</dc:date>
        <dc:format>157104 bytes</dc:format>
        <dc:format>application/pdf</dc:format>
        <dc:identifier>http://hdl.handle.net/2077/999999999</dc:identifier>
        <dc:language>en</dc:language>
        </oai_dc:dc>
      </metadata>
    </record>
  END

  xml_data_short = <<-END.gsub(/^ {6}/, '')
    <record>
      <header>
        <identifier>oai:gupea.ub.gu.se:2077/24</identifier>
        <datestamp>2013-04-23T09:43:42Z</datestamp>
        <setSpec>hdl_2077_21</setSpec>
      </header>
      <metadata>
        <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
        <dc:title>The Title is the title is the title</dc:title>
        <dc:creator>The Creator, Curt</dc:creator>
        <dc:description>This paper deals with...</dc:description>
        <dc:date>2005-04-26T12:02:50Z</dc:date>
        <dc:date>2005-04-26T12:02:50Z</dc:date>
        <dc:date>2003-11</dc:date>
        <dc:format>157104 bytes</dc:format>
        <dc:format>application/pdf</dc:format>
        <dc:identifier>http://hdl.handle.net/2077/999999999</dc:identifier>
        <dc:language>en</dc:language>
        </oai_dc:dc>
      </metadata>
    </record>
  END

  xml_data_simple = <<-END.gsub(/^ {6}/, '')
    <simpledc xmlns="http://www.ub.gu.se/xml-schemas/simple-dc/v1/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.ub.gu.se/xml-schemas/simple-dc/v1/ http://www.ub.gu.se/xml-schemas/simple-dc/gub-simple-dc-20150812.xsd">
      <dc:title>The Title</dc:title>
      <dc:creator>The Creator</dc:creator>
      <dc:subject>The Subject</dc:subject>
      <dc:description/>
      <dc:publisher/>
      <dc:contributor/>
      <dc:date/>
      <dc:type/>
      <dc:format/>
      <dc:identifier/>
      <dc:source/>
      <dc:language/>
      <dc:relation/>
      <dc:coverage/>
      <dc:rights/>
    </simpledc>
END
  #   <record>
  #     <title>The Title is the title is the title</title>
  #     <creator>The Creator, Curt</creator>
  #     <description>This paper deals with...</description>
  #     <date>2005-04-26T12:02:50Z</date>
  #     <format>application/pdf</format>
  #     <identifier>http://hdl.handle.net/2077/999999999</identifier>
  #     <language>en</language>
  #   </record>
  # END

  dc = {
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

  xml_data_generated = <<-END.gsub(/^ {6}/, '')
    <?xml version="1.0" encoding="UTF-8"?>
    <simpledc xmlns="http://www.ub.gu.se/xml-schemas/simple-dc/v1/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.ub.gu.se/xml-schemas/simple-dc/v1/ http://www.ub.gu.se/xml-schemas/simple-dc/gub-simple-dc-20150812.xsd">
      <dc:title>#{dc[:title]}</dc:title>
      <dc:creator>#{dc[:creator]}</dc:creator>
      <dc:subject>#{dc[:subject]}</dc:subject>
      <dc:description>#{dc[:description]}</dc:description>
      <dc:publisher>#{dc[:publisher]}</dc:publisher>
      <dc:contributor>#{dc[:contributor]}</dc:contributor>
      <dc:date>#{dc[:date]}</dc:date>
      <dc:type>#{dc[:type]}</dc:type>
      <dc:format>#{dc[:format]}</dc:format>
      <dc:identifier>#{dc[:identifier]}</dc:identifier>
      <dc:source>#{dc[:source]}</dc:source>
      <dc:language>#{dc[:language]}</dc:language>
      <dc:relation>#{dc[:relation]}</dc:relation>
      <dc:coverage>#{dc[:coverage]}</dc:coverage>
      <dc:rights>#{dc[:rights]}</dc:rights>
    </simpledc>
  END

  dc_data = {
    xml: xml_data_simple
  }

  describe "find the source" do
    context "when correctly configured" do
      it "should find a class for the source" do
        my_source = Source.find_by_name('dcxml')
        expect(my_source).not_to be nil
        expect(my_source).to be DublinCoreXML
      end
    end
  end
  describe "fetch source data" do
    context "when dc data is provided" do
      it "should generate a catalog_id with the format dc:<uuid>" do
        data = @dcxml.fetch_source_data('dc', dc_data)
        expect(data[:catalog_id]).to start_with("dc:")
      end
      it "should find the title in title" do
        data = @dcxml.fetch_source_data('dc', dc_data)
        expect(data[:title]).to start_with("The Title")
      end
      it "should find the title in metadata" do
        data = @dcxml.fetch_source_data('dc', dc_data)
        expect(data[:metadata][:dc][:title]).to start_with("The Title")
      end
      it "should find the creator in metadata" do
        data = @dcxml.fetch_source_data('dc', dc_data)
        expect(data[:metadata][:dc][:creator]).to start_with("The Creator")
      end
    end
  end

  describe "parse_xml" do
    context "when xml data is same as if generated" do
      it "should find title in returned hash" do
        data = @dcxml.parse_xml(xml_data_generated)
        expect(data[:title]).to start_with("The Title")
      end
    end
    context "when xml data is simple" do
      it "should find title in returned hash" do
        data = @dcxml.parse_xml(xml_data_simple)
        expect(data[:title]).to start_with("The Title")
      end
    end
  end
end

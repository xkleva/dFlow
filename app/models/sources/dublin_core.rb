require 'sources/dublin_core_xml'

#
# Class for defining an import source for Jobs
# The data returned will be used for job creation
# Data is supporded in the following format:
# {title: "String", author: "String", metadata: {}, xml: "String", source_id: int, catalog_id: int}
#
class DublinCore < DublinCoreXML
  def self.validate_source_fields(params)
    return false if !params[:dc]
    return true if params[:dc][:title]
    false
  end

  # Returns a hash of data fetched from source
  # I builds xml, parses the xml,
  # constructs and returns job data.
  def self.fetch_source_data(catalog_id, extra_params={})
    job_data = {}
    xml = build_xml(extra_params)
    dc_data = parse_xml(xml)
    job_data = build_job_data(dc_data, xml)

    return job_data
  end

  # Builds the xml
  def self.build_xml(dc)
    dc.symbolize_keys!
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.simpledc(
          'xmlns' => 'http://www.ub.gu.se/xml-schemas/simple-dc/v1/',
          'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xsi:schemaLocation' => 'http://www.ub.gu.se/xml-schemas/simple-dc/v1/ http://www.ub.gu.se/xml-schemas/simple-dc/gub-simple-dc-20150812.xsd'
      ) do
        xml[:dc].title dc[:title] if !dc[:title].blank?
        xml[:dc].creator dc[:creator] if !dc[:creator].blank?
        xml[:dc].subject_ dc[:subject] if !dc[:subject].blank?
        xml[:dc].description dc[:description] if !dc[:description].blank?
        xml[:dc].publisher dc[:publisher] if !dc[:publisher].blank?
        xml[:dc].contributor dc[:contributor] if !dc[:contributor].blank?
        xml[:dc].date dc[:date] if !dc[:date].blank?
        xml[:dc].type dc[:type] if !dc[:type].blank?
        xml[:dc].format_ dc[:format] if !dc[:format].blank?
        xml[:dc].identifier dc[:identifier] if !dc[:identifier].blank?
        xml[:dc].source dc[:source] if !dc[:source].blank?
        xml[:dc].language dc[:language] if !dc[:language].blank?
        xml[:dc].relation dc[:relation] if !dc[:relation].blank?
        xml[:dc].coverage dc[:coverage] if !dc[:coverage].blank?
        xml[:dc].rights dc[:rights] if !dc[:rights].blank?
      end
    end
    builder.to_xml
  end
end

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

  # Validates fields of job object
  def self.validate_job_fields(object)
    object.each do |key,value|
      return false if !VALID_KEYS.include? key.to_s
    end
    true
  end

  # Returns a hash of data fetched from source
  # I builds xml, parses the xml,
  # constructs and returns job data.
  def self.fetch_source_data(catalog_id, dc={})
    job_data = {}
    xml = build_xml(dc)
    dc_data = parse_xml(xml)
    job_data = build_job_data(dc_data, xml)

    return job_data
  end

  def self.build_xml(dc)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.record do
        xml.title dc[:title]
        xml.creator dc[:creator]
        xml.subject_ dc[:subject]
        xml.description dc[:description]
        xml.publisher dc[:publisher]
        xml.contributor dc[:contributor]
        xml.date dc[:date]
        xml.type dc[:type]
        xml.format_ dc[:format]
        xml.identifier dc[:identifier]
        xml.source dc[:source]
        xml.language dc[:language]
        xml.relation dc[:relation]
        xml.coverage dc[:coverage]
        xml.rights dc[:rights]
      end
    end
    builder.to_xml
  end
end

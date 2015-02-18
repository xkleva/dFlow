#
# Class for defining an import source for Jobs
# The data returned will be used for job creation
# Data is supporded in the following format:
# {title: "String", author: "String", metadata: {}, xml: "String", source_id: int, catalog_id: int}
#

require 'open-uri'

class Libris < Source
  # There is no schema for libris right now
  XML_SCHEMA = nil
  LIBRIS_XSEARCH_MARC = "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:"
  VALID_KEYS = ["source_name", "source_id", "catalog_id", "name", "metadata", "title", "author", "object_info", "comment", "flow_id", "flow_params"]

  # Validates fields of job object
  def self.validate_job_fields(object)
    object.each do |key,value|
      return false if !VALID_KEYS.include? key.to_s
    end
    true
  end

  # Returns a hash of data fetched from source
  def self.fetch_source_data(catalog_id)
    url = URI.parse(LIBRIS_XSEARCH_MARC+catalog_id.to_s)
    job_data = {}
    job_data = fetch_from_libris(url)
    job_data[:catalog_id] = catalog_id if not job_data.blank?
    return job_data
  rescue Exception => e
    pp "Error in fetch_source_data #{e.message}"
    return {}
  end

  private

  def self.fetch_from_libris(url)
    job_data = {}
    open(url) do |conn|
      librisdata = conn.read
      librisdoc = Nokogiri::XML(librisdata)
      librisdoc.remove_namespaces!
      record = librisdoc.search("/xsearch/collection/record").first
      job_data = data_from_record(record)
      job_data[:xml] = librisdata if not job_data.blank?
    end
    return job_data
  rescue Exception => e
    pp "Error in fetch_from_libris #{e.message}"
    return {}
  end

  def self.data_from_record(record)
    job_data = {}
    marc_record = MARC::XMLReader.new(StringIO.new(record.to_xml)).first
    job_data[:title] = [marc_record['245']['a'],marc_record['245']['b']].compact.join(" ")
    job_data[:author] = marc_record['100']['a'] if marc_record['100']
    job_data[:metadata] = {}
    job_data[:metadata][:type_of_record] =  marc_record.leader[6..7]
    job_data[:source_name] = Source.find_name_by_class_name(self.name)
    return job_data
  rescue Exception => e
    pp "Error in data_from_record #{e.message}"
    return {}
  end

end

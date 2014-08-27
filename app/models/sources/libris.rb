require 'open-uri'

class Libris
  # There is no schema for libris right now
  SOURCE_ID = 1
  XML_SCHEMA = nil
  LIBRIS_XSEARCH_MARC = "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:"

  # Returns a hash of data fetched from source
  def self.fetch_source_data(catalog_id)
    url = URI.parse(LIBRIS_XSEARCH_MARC+catalog_id.to_s)
    job_data = {}
    begin
      open(url) do |conn|
        librisdata = conn.read
        librisdoc = Nokogiri::XML(librisdata)
        librisdoc.remove_namespaces!
        record = librisdoc.search("/xsearch/collection/record").first
        marc_record = MARC::XMLReader.new(StringIO.new(record.to_xml)).first
        job_data[:title] = [marc_record['245']['a'],marc_record['245']['b']].compact.join(" ")
        job_data[:author] = marc_record['100']['a'] if marc_record['100']
        job_data[:metadata] = {}
        job_data[:metadata][:type_of_record] =  marc_record.leader[6..7]
        job_data[:xml] = librisdata
        job_data[:source_id] = Source.where(classname: self.name).first.id
        job_data[:catalog_id] = catalog_id
      end
    rescue
      return {}
    end
    return job_data
  end

end
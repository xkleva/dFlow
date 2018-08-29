#
# Class for defining an import source for Jobs
# The data returned will be used for job creation
# Data is supporded in the following format:
# {title: "String", author: "String", metadata: {}, xml: "String", source_id: int, catalog_id: int}
#
class DublinCoreXML < Source

  # Returns a hash of data fetched from source
  # Parse the given dc-parameter turn it into job_data
  def self.fetch_source_data(catalog_id, extra_params={})
    job_data = {}
    xml = extract_xml(extra_params)
    dc_data = parse_xml(xml)
    job_data = build_job_data(dc_data, xml)
    return job_data
  end

  @@dc_terms = [
    :title,
    :creator,
    :subject,
    :description,
    :publisher,
    :contributor,
    :date,
    :type,
    :format,
    :identifier,
    :source,
    :language,
    :relation,
    :coverage,
    :rights
  ]

  private

  def self.extract_xml(extra_params)
    xml = extra_params[:xml]
    return xml
  end

  # Parse the given xml, look for dublin core terms.
  # Put them in a hash if found and return that hash.
  def self.parse_xml(xml)
    dc = {}
    doc = Nokogiri::XML(xml)
    @@dc_terms.each do |dc_term|
      term = doc.search("//dc:#{dc_term}").text
      dc[dc_term] = term if not term.blank?
    end
    return dc
  end

  # In order to build the job data we need
  # a catalog_id
  def self.build_job_data(dc, xml)
    metadata = {
      type_of_record: dc[:type],
      dc: dc
    }
    job_data = {
      title: dc[:title],
      author: dc[:creator],
      metadata: metadata,
      source_name: Source.find_name_by_class_name(self.name),
      catalog_id: generate_catalog_id(),
      xml: xml
    }
    return job_data
  end

  def self.generate_catalog_id()
    "dc:#{SecureRandom.uuid}"
  end

end

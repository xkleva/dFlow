class Document < Source
  FETCH_URL="http://www.ub.gu.se/handskriftsdatabasen/api/getdocument.xml"
  REQUIRED_SOURCE_FIELDS = ["id"]

  def self.validate_source_fields(params)
    return true if params[:catalog_id].present?
    false
  end

  def self.fetch_url(catalog_id)
    url = URI.parse(FETCH_URL)
    url.query = {
      id: catalog_id
    }.to_param
    url
  end

  def self.fetch_source_data(catalog_id, extra_params={})
    data = nil
    open(fetch_url(catalog_id)) do |u| 
      data = u.read
    end
    
    record = Nokogiri::XML(data)
    job_data = data_from_record(record)
    job_data[:xml] = data if job_data.present?
    job_data[:catalog_id] = catalog_id if job_data.present?
    job_data
  end

  def self.data_from_record(doc)
    if doc.search("/manuscript/error").present?
      return {}
    end
    
    archive_title = doc.search("/manuscript/archive/unittitle").text
    title = doc.search("/manuscript/document/unittitle").text
    archive_physloc = doc.search("/manuscript/archive/physloc").text
    archive_physloc = nil if archive_physloc.blank?
    document_physloc = doc.search("/manuscript/document/physloc").text
    document_physloc = nil if document_physloc.blank?
    physloc = [archive_physloc.strip, document_physloc.strip].compact.join(" # ")
    physdesc = doc.search("/manuscript/document/physdesc").text
    physdesc = physdesc.strip if physdesc

    originator_given = doc.search("/manuscript/document/originator/name-given").text
    originator_family = doc.search("/manuscript/document/originator/name-family").text
    originator_institution = doc.search("/manuscript/document/originator/name-institution").text
    originator_given = nil if originator_given.blank?
    originator_family = nil if originator_family.blank?
    originator = nil
    originator = originator_institution.strip if !originator_institution.blank?
    if originator_institution.blank?
      originator = [originator_given.strip, originator_family.strip].compact.join(" ") 
    end
    author = originator

    metadata = {
      type_of_record: "tm",
      archive: archive_title.strip,
      location: physloc,
      scope: physdesc
    }

    job_data = {
      title: title.strip,
      author: author.strip,
      metadata: metadata,
      source_name: Source.find_name_by_class_name(self.name)
    }
    job_data
  end
end

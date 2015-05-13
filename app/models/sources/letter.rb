# -*- coding: utf-8 -*-
class Letter < Source
  FETCH_URL="http://www.ub.gu.se/handskriftsdatabasen/api/getletter.xml"
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
    archive_physloc = doc.search("/manuscript/archive/physloc").text
    archive_physloc = nil if archive_physloc.blank?
    letter_physloc = doc.search("/manuscript/letter/physloc").text
    letter_physloc = nil if letter_physloc.blank?
    physloc = [archive_physloc.strip, letter_physloc.strip].compact.join(" # ")
    dated = doc.search("/manuscript/letter/dated").text.to_i
    undated = doc.search("/manuscript/letter/undated").text.to_i
    total = dated + undated
    unitdate = doc.search("/manuscript/letter/unitdate").text

    sender_given = doc.search("/manuscript/letter/sender/name-given").text
    sender_family = doc.search("/manuscript/letter/sender/name-family").text
    sender_institution = doc.search("/manuscript/letter/sender/name-institution").text
    sender_given = nil if sender_given.blank?
    sender_family = nil if sender_family.blank?
    recipient_given = doc.search("/manuscript/letter/recipient/name-given").text
    recipient_family = doc.search("/manuscript/letter/recipient/name-family").text
    recipient_institution = doc.search("/manuscript/letter/recipient/name-institution").text
    recipient_given = nil if recipient_given.blank?
    recipient_family = nil if recipient_family.blank?
    sender = nil
    recipient = nil
    sender_given = sender_given.strip if sender_given
    sender_family = sender_family.strip if sender_family
    recipient_given = recipient_given.strip if recipient_given
    recipient_family = recipient_family.strip if recipient_family

    sender = sender_institution.strip if !sender_institution.blank?
    sender = [sender_given, sender_family].compact.join(" ") if sender_institution.blank?

    recipient = recipient_institution.strip if !recipient_institution.blank?
    recipient = [recipient_given, recipient_family].compact.join(" ") if recipient_institution.blank?

    unitdate = unitdate.strip if unitdate

    title = "Brev från #{sender} till #{recipient} #{unitdate}"
    author = sender

    metadata = {
      type_of_record: "tm",
      archive: archive_title.strip,
      location: physloc,
      scope: "#{total} (#{dated}+#{undated})"
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

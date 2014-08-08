
# -*- coding: utf-8 -*-
class Document < Manuscript
  FETCH_URL="http://www.ub.gu.se/handskriftsdatabasen/api/getdocument.xml?id="

  def self.create_job(user_id, project_id, document_id)
    document = self.new(user_id, project_id, document_id)
    document.fetch_manuscriptdata_xml
    document.parse_xml(:remove_data)

    return document.create_job
  end

  def self.refetch_xml(job)
    document = self.new(job.user_id, job.project_id, job.catalog_id)
    document.refetch_xml_generic(job, FETCH_URL)
  end

  def self.clean_xml_groups(job, group_name_list)
    group_name_list = group_name_list.map(&:to_i)
    doc = Nokogiri::XML(job.xml)
    doc.search('/manuscript/document/data/imagedata').each do |imagedata|
      next if group_name_list.include?(imagedata.attr('hd-id').to_i)
      imagedata.remove
    end
    job.update_attribute(:xml, doc.to_xml)
  end

  def self.copyright_id_from_source(job)
    doc = Nokogiri::XML(job.xml)
    doc.search("/manuscript/document/data/imagedata").each do |imagedata|
      # 3 in imagedata means publishable. Everything else is not.
      if imagedata.search("userestrict").text.to_i != 3
        return 1 # (1 in copyright == May not publish) (see config.rb)
      end
    end
    return 2 # (2 in copyright == May publish) (see config.rb)
  end

  def self.mets_extra_dmdsecs(job, creation_date)
    doc = Nokogiri::XML(job.xml)
    doc.search("/manuscript/document/data/imagedata").map do |imagedata|
      imagedata_id = imagedata.attr('hd-id').to_i
      mets_extra_dmdsec("image_#{imagedata_id}", creation_date, xml_type(job), imagedata.to_xml)
    end.join("\n")
  end

  def initialize(user_id, project_id, document_id)
    super(user_id, project_id, document_id, FETCH_URL)
  end

  def create_job
    Job.new(job_params)
  end

  def parse_xml(remove_data = false)
    doc = Nokogiri::XML(self.xml)
    if remove_data == :remove_data
      doc.search("/manuscript/document/data").each { |node| node.remove }
      self.xml = doc.to_xml
    end

    archive_title = doc.search("/manuscript/archive/unittitle").text
    @title = doc.search("/manuscript/document/unittitle").text
    archive_physloc = doc.search("/manuscript/archive/physloc").text
    archive_physloc = nil if archive_physloc.blank?
    document_physloc = doc.search("/manuscript/document/physloc").text
    document_physloc = nil if document_physloc.blank?
    physloc = [archive_physloc, document_physloc].compact.join(" # ")
    physdesc = doc.search("/manuscript/document/physdesc").text

    originator_given = doc.search("/manuscript/document/originator/name-given").text
    originator_family = doc.search("/manuscript/document/originator/name-family").text
    originator_institution = doc.search("/manuscript/document/originator/name-institution").text
    originator_given = nil if originator_given.blank?
    originator_family = nil if originator_family.blank?
    originator = nil
    originator = originator_institution if !originator_institution.blank?
    originator = [originator_given, originator_family].compact.join(" ") if originator_institution.blank?
    @author = originator

    @metadata ||= []
    @metadata << ["type_of_record", "tm", "string"]
    @metadata << ["archive", archive_title, "string"]
    @metadata << ["location", physloc, "string"]
    @metadata << ["scope", physdesc, "string"]
  end
  
  def self.validate_group_name(job, group_name)
    doc = Nokogiri::XML(job.xml)
    doc.search('/manuscript/document/data/imagedata').each do |imagedata|
      return true if imagedata.attr('hd-id').to_i == group_name.to_i
    end
    false
  end
end

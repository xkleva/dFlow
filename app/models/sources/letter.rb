# -*- coding: utf-8 -*-
class Letter < Manuscript
  FETCH_URL="http://www.ub.gu.se/handskriftsdatabasen/api/getletter.xml?id="

  def self.create_job(user_id, project_id, letter_id)
    letter = self.new(user_id, project_id, letter_id)
    letter.fetch_manuscriptdata_xml
    letter.parse_xml(:remove_data)

    return letter.create_job
  end

  def self.refetch_xml(job)
    letter = self.new(job.user_id, job.project_id, job.catalog_id)
    letter.refetch_xml_generic(job, FETCH_URL)
  end

  def self.clean_xml_groups(job, group_name_list)
    group_name_list = group_name_list.map(&:to_i)
    doc = Nokogiri::XML(job.xml)
    doc.search('/manuscript/letter/data/imagedata').each do |imagedata|
      next if group_name_list.include?(imagedata.attr('hd-id').to_i)
      imagedata.remove
    end
    job.update_attribute(:xml, doc.to_xml)
  end

  def self.copyright_id_from_source(job)
    doc = Nokogiri::XML(job.xml)
    doc.search("/manuscript/letter/data/imagedata").each do |imagedata|
      # 3 in imagedata means publishable. Everything else is not.
      if imagedata.search("userestrict").text.to_i != 3
        return 1 # (1 in copyright == May not publish) (see config.rb)
      end
    end
    return 2 # (2 in copyright == May publish) (see config.rb)
  end

  def self.mets_extra_dmdsecs(job, creation_date)
    doc = Nokogiri::XML(job.xml)
    doc.search("/manuscript/letter/data/imagedata").map do |imagedata|
      imagedata_id = imagedata.attr('hd-id').to_i
      mets_extra_dmdsec("image_#{imagedata_id}", creation_date, xml_type(job), imagedata.to_xml)
    end.join("\n")
  end

  def initialize(user_id, project_id, letter_id)
    super(user_id, project_id, letter_id, FETCH_URL)
  end

  def create_job
    Job.new(job_params)
  end

  def parse_xml(remove_data = false)
    doc = Nokogiri::XML(self.xml)

    if remove_data == :remove_data
      doc.search("/manuscript/letter/data").each { |node| node.remove }
      self.xml = doc.to_xml
    end

    archive_title = doc.search("/manuscript/archive/unittitle").text
    archive_physloc = doc.search("/manuscript/archive/physloc").text
    archive_physloc = nil if archive_physloc.blank?
    letter_physloc = doc.search("/manuscript/letter/physloc").text
    letter_physloc = nil if letter_physloc.blank?
    physloc = [archive_physloc, letter_physloc].compact.join(" # ")
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

    sender = sender_institution if !sender_institution.blank?
    sender = [sender_given, sender_family].compact.join(" ") if sender_institution.blank?

    recipient = recipient_institution if !recipient_institution.blank?
    recipient = [recipient_given, recipient_family].compact.join(" ") if recipient_institution.blank?

    @title = "Brev från #{sender} till #{recipient} #{unitdate}"
    @author = sender

    @metadata ||= []
    @metadata << ["type_of_record", "tm", "string"]
    @metadata << ["archive", archive_title, "string"]
    @metadata << ["location", physloc, "string"]
    @metadata << ["scope", "#{total} (#{dated}+#{undated})", "string"]
  end
  
  def self.validate_group_name(job, group_name)
    doc = Nokogiri::XML(job.xml)
    doc.search('/manuscript/letter/data/imagedata').each do |imagedata|
      return true if imagedata.attr('hd-id').to_i == group_name.to_i
    end
    false
  end
end

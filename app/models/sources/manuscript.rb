# -*- coding: utf-8 -*-
class Manuscript < SourceBase
  XML_SCHEMA="http://www.ub.gu.se/handskriftsdatabasen/api/schema.xsd"

  def fetch_manuscriptdata_xml
    begin
      open(@fetch_url+@catalog_id.to_s) do |conn|
        self.xml = conn.read
        raise SourceBase::SourceFetchFailed if has_error?
        clean_xml
        clean_xml
      end
    rescue
      raise SourceBase::SourceFetchFailed
    end
  end

  def update_job_xml(job)
    job.update_attribute(:xml, self.xml)
  end

  def initialize(user_id, project_id, manuscript_id, fetch_url)
    @fetch_url = fetch_url
    super(user_id, project_id, manuscript_id)
  end

  def has_error?
    doc = Nokogiri::XML(@xml)
    return false if doc.search("/manuscript/error").text.blank?
    true
  end

  def clean_xml
    doc = Nokogiri::XML(@xml, &:noblanks)
    clean_xml_traverse(doc)
    @xml = doc.to_xml(encoding:'utf-8')
  end

  def clean_xml_traverse(docroot)
    docroot.children.each do |element|
      if element.is_a?(Nokogiri::XML::Element)
        if element.children.blank?
          element.remove
        else
          clean_xml_traverse(element)
        end
      end
      if element.is_a?(Nokogiri::XML::Text)
        element.content = element.text.gsub(/^\s*/,'').gsub(/\s*$/,'')
      end
    end
  end

  def self.xslt
    Nokogiri::XSLT(File.read("#{Rails.root}/app/assets/xsl/gubs.xsl"))
  end

  def self.xml_data(job)
    xml = job.xml || ""
    xml.gsub!(/<\?xml version="1.0" encoding="utf-8"\?>/,'')
    "<gubs>#{xml}</gubs>"
  end

  def self.xml_type(job)
    "OTHER"
  end

  def self.mets_extra_dmdsec(dmdid, creation_date, mdtype, xml)
    %Q(<mets:dmdSec ID="#{dmdid}" CREATED="#{creation_date}">
        <mets:mdWrap MDTYPE="#{mdtype}">
         <mets:xmlData>
          <pagegroup xsi:noNamespaceSchemaLocation="http://www.ub.gu.se/handskriftsdatabasen/api/imagedata.xsd">
           #{xml}
          </pagegroup>
         </mets:xmlData>
        </mets:mdWrap>
       </mets:dmdSec>)
  end

  def self.mets_dmdid_attribute(job, group_name)
    " DMDID=\"image_#{group_name}\""
  end

  def self.advanced_covers?
    false
  end

  def refetch_xml_generic(job, fetch_url)
    begin
      fetch_manuscriptdata_xml
      update_job_xml(job)
    rescue SourceBase::SourceFetchFailed
      job.set_quarantine(I18n.t("jobs.errors.source_not_responding"))
    end
  end

  

  def self.search_title(job)
    #archive_title = job.job_metadata.find_by_key("archive")
    #archive_title = archive_title ? archive_title.value : ""
    #location = job.job_metadata.find_by_key("location")
    #location = location ? location.value : ""
    #"#{archive_title} #{location}"
  end

  #Defines if copyright shall be inherited from source or set at job creation
  def self.copyright_from_source?
    true
  end

  def self.schema_validation(job)
    return true if !XML_SCHEMA
    doc = Nokogiri::XML(job.xml)
    open(XML_SCHEMA) do |xsd_file|
      xsd = Nokogiri::XML::Schema(xsd_file.read)
      xsd.validate(doc).each do |error|
        job.set_quarantine(I18n.t("jobs.errors.schema_does_not_validate_xml")+": #{error.message}")
        return nil
      end
    end
    return true
  end
end

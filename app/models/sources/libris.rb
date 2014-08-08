# -*- coding: utf-8 -*-
class Libris < SourceBase
  # There is no schema for libris right now
  XML_SCHEMA=nil
  LIBRIS_XSEARCH_MARC="http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:"
  LIBRIS_XSEARCH_MODS="http://libris.kb.se/xsearch?format=mods&format_level=full&holdings=true&query=ONR:"

  def self.create_job(user_id, project_id, libris_id)
    libris = self.new(user_id, project_id, libris_id)
    begin
      libris.fetch_librisdata_mods
      libris.fetch_librisdata_marc
    rescue
      raise SourceBase::SourceFetchFailed
    end

    return libris.create_job
  end

  def self.refetch_xml(job)
    # Do nothing
    true
  end

  def self.clean_xml_groups(job, group_name_list)
    # Do nothing
    true
  end

  def initialize(user_id, project_id, libris_id)
    super(user_id, project_id, libris_id) # @catalog_id
  end

  def create_job
    Job.new(job_params)
  end

  def fetch_librisdata_mods
    open(LIBRIS_XSEARCH_MODS+@catalog_id.to_s) do |conn|
      librisdata = conn.read
      self.mods = librisdata
    end
    self.mods
  end

  def fetch_librisdata_marc
    open(LIBRIS_XSEARCH_MARC+@catalog_id.to_s) do |conn|
      librisdata = conn.read
      librisdoc = Nokogiri::XML(librisdata)
      librisdoc.remove_namespaces!
      record = librisdoc.search("/xsearch/collection/record").first
      marc_record = MARC::XMLReader.new(StringIO.new(record.to_xml)).first
      self.title = [marc_record['245']['a'],marc_record['245']['b']].compact.join(" ")
      self.author = marc_record['100']['a'] if marc_record['100']
      self.metadata ||= []
      self.metadata << ["type_of_record", marc_record.leader[6..7], "string"]
      #self.job_metadata.build(:key => "type_of_record", :value => marc_record.leader[6..7], :metadata_type => "string")
      self.xml = librisdata
    end
    self.xml
  end

  def self.xslt
    Nokogiri::XSLT(File.read("#{Rails.root}/app/assets/xsl/marc.xsl"))
  end

  def self.xml_data(job)
    "<mods>#{alvin_mods(job)}</mods>"
  end

  def self.xml_type(job)
    "MODS"
  end

  def self.mets_extra_dmdsecs(job, creation_date)
    ""
  end

  def self.mets_dmdid_attribute(job, group_name)
    ""
  end

  def self.advanced_covers?
    true
  end

  def self.validate_group_name(job, group_name)
    # Libris doesn't care about group name. Just return true.
    true
  end

  def self.is_serial?(job)
    job.type_of_record == "as"
  end

  def self.alvin_xslt
    @@alvin_xslt ||= Nokogiri::XSLT(File.open("#{Rails.root}/app/assets/xsl/LibrisToAlvin.xsl", "rb"))
  end

  def self.alvin_mods(job)
    alvin_xml = alvin_xslt.transform(Nokogiri::XML(job.xml)).search("mods").first
    is_serial?(job) ? alvin_append_serial(job, alvin_xml).inner_html : alvin_xml.inner_html
  end

  def self.alvin_append_serial(job, a_mods)
    a_part = Nokogiri::XML::Node.new('part', a_mods)
    job.ordinals(true).each_with_index do |ordinal,i|
      a_detail = Nokogiri::XML::Node.new('detail', a_part)
      a_detail.set_attribute('type', "ordinal_#{i+1}")
      a_number = Nokogiri::XML::Node.new('number', a_detail)
      a_number.inner_html = ordinal[1].to_s
      a_detail.add_child(a_number)
      a_caption = Nokogiri::XML::Node.new('caption', a_detail)
      a_caption.inner_html = ordinal[0].to_s
      a_detail.add_child(a_caption)
      a_part.add_child(a_detail)
    end
    job.chronologicals(true).each_with_index do |chronological,i|
      a_detail = Nokogiri::XML::Node.new('detail', a_part)
      a_detail.set_attribute('type', "chronological_#{i+1}")
      a_number = Nokogiri::XML::Node.new('number', a_detail)
      a_number.inner_html = chronological[1].to_s
      a_detail.add_child(a_number)
      a_caption = Nokogiri::XML::Node.new('caption', a_detail)
      a_caption.inner_html = chronological[0].to_s
      a_detail.add_child(a_caption)
      a_part.add_child(a_detail)
    end
    a_mods.add_child(a_part)
    a_mods
  end

  def self.search_title(job)
    "#{job.title} #{job.ordinals_and_chronologicals}"
  end

  def self.schema_validation(job)
    return true if !XML_SCHEMA
  end
end

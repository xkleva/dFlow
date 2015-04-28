#
# Class for defining an import source for Jobs
# The data returned will be used for job creation
# Data is supporded in the following format:
# {title: "String", author: "String", metadata: {}, xml: "String", source_id: int, catalog_id: int}
#

require 'open-uri'

class DublinCore < Source
  # There is no schema for libris right now
  XML_SCHEMA = nil
  VALID_KEYS = ["source_name", "source_id", "catalog_id", "name", "metadata", "title", "author", "object_info", "comment", "flow_id", "flow_params"]
  DC_KEYS = [
    "title",
    "creator",
    "subject",
    "description",
    "publisher",
    "contributor",
    "date",
    "type",
    "format",
    "identifier",
    "source",
    "language",
    "relation",
    "coverage",
    "rights"
  ]

  attr_accessor :catalog_id
  attr_accessor :dc_title
  attr_accessor :dc_creator
  attr_accessor :dc_subject
  attr_accessor :dc_description
  attr_accessor :dc_publisher
  attr_accessor :dc_contributor
  attr_accessor :dc_date
  attr_accessor :dc_type
  attr_accessor :dc_format
  attr_accessor :dc_identifier
  attr_accessor :dc_source
  attr_accessor :dc_language
  attr_accessor :dc_relation
  attr_accessor :dc_coverage
  attr_accessor :dc_rights

  # Validates fields of job object
  def self.validate_job_fields(object)
    object.each do |key,value|
      return false if !VALID_KEYS.include? key.to_s
    end
    true
  end

  # Returns a hash of data fetched from source
  def self.fetch_source_data(catalog_id, params={})
    job_data = {}
    job_data = populate_with_dc(catalog_id, params)
    job_data[:catalog_id] = generate_catalog_id()
    return job_data
  end

  private

  def self.populate_with_dc(catalog_id, params={})
    job_data = {}
    dc_data = dc_data_from_params(params)
    job_data[:title] = dc_data[:dc_title] ? dc_data[:dc_title] : ""
    job_data[:author] = dc_data[:dc_creator] ? dc_data[:dc_creator] : ""
    job_data[:metadata] = dc_data
    job_data[:metadata][:type_of_record] =  ""
    job_data[:source_name] = Source.find_name_by_class_name(self.name)
    return job_data
  end

  # dc_data is a hash with keys corresponding to the dc terms.
  # Since each dc_term might have multiple values each dc_term
  # has the values in an array.
  def self.dc_data_from_params(params)
    dc_data = {}
    if (params)
      dc_data[:dc_title] = params[:dc_title]
      dc_data[:dc_creator] = params[:dc_creator]
      dc_data[:dc_subject] = params[:dc_subject]
      dc_data[:dc_description] = params[:dc_description]
      dc_data[:dc_publisher] = params[:dc_publisher]
      dc_data[:dc_contributor] = params[:dc_contributor]
      dc_data[:dc_date] = params[:dc_date]
      dc_data[:dc_type] = params[:dc_type]
      dc_data[:dc_format] = params[:dc_format]
      dc_data[:dc_identifier] = params[:dc_identifier]
      dc_data[:dc_source] = params[:dc_source]
      dc_data[:dc_language] = params[:dc_language]
      dc_data[:dc_relation] = params[:dc_relation]
      dc_data[:dc_coverage] = params[:dc_coverage]
      dc_data[:dc_rights] = params[:dc_rights]
      return dc_data
    else
      pp "No valid dc parameters"
      return {}
    end
  end

  def self.generate_catalog_id()
    "dc:#{SecureRandom.uuid}"
  end

end

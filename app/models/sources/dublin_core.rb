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
  DC_KEYS = ["creator", "creator", "subject", "description", "publisher", "contributor", "date", "type", "format", "identifier", "source", "language", "relation", "coverage", "rights"]

  # Validates fields of job object
  def self.validate_job_fields(object)
    object.each do |key,value|
      return false if !VALID_KEYS.include? key.to_s
    end
    true
  end

  # Returns a hash of data fetched from source
  def self.fetch_source_data(dc_hash)
    job_data = {}
    job_data = populate_with_dc(dc_hash)
    #job_data[:catalog_id] = catalog_id if not job_data.blank?
    return job_data
  end

  private

  def self.populate_with_dc(dc_hash)
    job_data = {}
    # TODO pupulate job with DC data
    job_data = data_from_dc(dc_data)
    return job_data
  end

  def self.data_from_dc(dc_data)
    job_data = {}
    if (dc_data)
      job_data[:title] = ""
      job_data[:author] = ""
      job_data[:metadata] = {}
      job_data[:metadata][:type_of_record] =  ""
      job_data[:source_name] = Source.find_name_by_class_name(self.name)
      return job_data
    else
      pp "No valid record"
      return {}
    end
  end

end

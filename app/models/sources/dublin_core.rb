#
# Class for defining an import source for Jobs
# The data returned will be used for job creation
# Data is supporded in the following format:
# {title: "String", author: "String", metadata: {}, xml: "String", source_id: int, catalog_id: int}
#
class DublinCore < Source
  def self.validate_source_fields(params)
    return false if !params[:dc]
    return true if params[:dc][:title]
    false
  end

  # Validates fields of job object
  def self.validate_job_fields(object)
    object.each do |key,value|
      return false if !VALID_KEYS.include? key.to_s
    end
    true
  end

  # Returns a hash of data fetched from source
  def self.fetch_source_data(catalog_id, dc={})
    job_data = {}
    job_data = populate_with_dc(catalog_id, dc)
    job_data[:catalog_id] = generate_catalog_id()
    return job_data
  end

  private

  def self.populate_with_dc(catalog_id, dc)
    metadata = {
      type_of_record: '',
      dc: dc
    }
    job_data = {
      title: dc[:title],
      author: dc[:creator],
      metadata: metadata,
      source_name: Source.find_name_by_class_name(self.name)
    }
    return job_data
  end

  def self.generate_catalog_id()
    "dc:#{SecureRandom.uuid}"
  end

end

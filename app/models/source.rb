class Source < ActiveRecord::Base

  def fetch_source_data(catalog_id)
    class_call(:fetch_source_data, catalog_id)
  end

  def validate_job_fields(object)
    class_call(:validate_job_fields, object)
  end

  def class_call(*args)
    Kernel.const_get(classname).send(*args)
  end
end

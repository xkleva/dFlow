class Source < ActiveRecord::Base
  attr_accessible :classname

  def xml_data(job)
    class_call(:xml_data, job)
  end

  def xml_type(job)
    class_call(:xml_type, job)
  end

  def advanced_covers?
    class_call(:advanced_covers?)
  end

  def refetch_xml(job)
    class_call(:refetch_xml, job)
  end

  def clean_xml_groups(job, group_name_list)
    class_call(:clean_xml_groups, job, group_name_list)
  end

  def validate_group_name(job, group_name)
    class_call(:validate_group_name, job, group_name)
  end

  def create_job(user_id, project_id, catalog_id)
    class_call(:create_job, user_id, project_id, catalog_id)
  end

  def xslt
    class_call(:xslt)
  end

  def search_title(job)
    class_call(:search_title, job)
  end

  def copyright_from_source?
    class_call(:copyright_from_source?)
  end

  def schema_validation(job)
    class_call(:schema_validation, job)
  end

  def mets_extra_dmdsecs(job, creation_date)
    class_call(:mets_extra_dmdsecs, job, creation_date)
  end

  def mets_dmdid_attribute(job, group_name)
    class_call(:mets_dmdid_attribute, job, group_name)
  end

  def copyright_id_from_source(job)
    class_call(:copyright_id_from_source, job)
  end

  def class_call(*args)
    Kernel.const_get(classname).send(*args)
  end
end

# -*- coding: utf-8 -*-
class SourceBase
  class SourceFetchFailed < Exception
  end

  attr_accessor :author, :barcode, :catalog_id, :created_by, :deleted_at, :deleted_by, :name, :project_id, :status_id, :title, :updated_by, :user_id, :xml, :mods, :quarantined, :priority, :object_info, :comment, :copyright, :page_count, :guessed_page_count, :source_id
  attr_accessor :metadata

  def initialize(user_id, project_id, catalog_id)
    @user_id = user_id
    @project_id = project_id
    @catalog_id = catalog_id
  end

  def new_job_status_id
    Status.find_by_name("create_begin").id
  end

  def source_id
    Source.find_by_classname(self.class.name).id
  end

  def job_params
    {
      user_id: @user_id,
      project_id: @project_id,
      catalog_id: @catalog_id,
      mods: @mods,
      xml: @xml,
      title: @title,
      author: @author,
      metadata: @metadata,
      source_id: source_id,
      status_id: new_job_status_id
    }
  end

  #Defines if copyright shall be inherited from source or set at job creation
  def self.copyright_from_source?
    false
  end

  def self.copyright_id_from_source(job)
    nil
  end
end

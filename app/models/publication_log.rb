class PublicationLog < ActiveRecord::Base

  def self.types
    return APP_CONFIG['publication_types'] || []
  end

end

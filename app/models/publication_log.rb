class PublicationLog < ActiveRecord::Base

  belongs_to :job

  def self.types
    types =  APP_CONFIG['publication_types'] || []
    types << "OTHER"
    types = types.uniq
    return types
  end

  validates :publication_type, :inclusion => {:in => PublicationLog.types}
end

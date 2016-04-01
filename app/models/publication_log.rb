class PublicationLog < ActiveRecord::Base

  belongs_to :job

  def self.types
    types =  SYSTEM_DATA['publication_types'] || []
    types << "OTHER"
    types = types.uniq
    return types
  end

  validates :publication_type, :inclusion => {:in => PublicationLog.types}
end

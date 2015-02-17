require 'nokogiri'

class Job < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  scope :active, -> {where(quarantined: false, deleted_at: nil)}

  belongs_to :treenode
  has_many :entries

  validates :title, :presence => true
  validates :catalog_id, :presence => true
  validates :treenode_id, :presence => true
  validates :source, :presence => true, inclusion: Rails.configuration.sources.map { |x| x[:name] }
  validate :xml_validity

  def as_json(options = {})
    if options[:list]
      { 
        id: id,
        name: name,
        title: title,
        display: display,
        source: source,
        catalog_id: catalog_id
      }
    else
      super.merge({
        display: display
      })
    end
  end

  # Generate preferred display name if name works
  def display
    name ? "#{name} (#{title})" : title
  end

  ###VALIDATION METHODS###
  def xml_valid?(xml)
    test=Nokogiri::XML(xml)
    test.errors.empty?
  end

  # Checks validity
  def xml_validity
    errors.add(:base, "Marc must be valid xml") unless xml_valid?(xml)
  end

  ########################

  # Returns the current workflowStep if any
  def current_entry
    entries.most_recent
  end

  # Updates metadata for a specific key
  def update_metadata_key(key, metadata)
    metadata_temp = JSON.parse(self.metadata || '{}')
    metadata_temp[key] = metadata
    self.metadata = metadata_temp.to_json
  end

  # Updates flow parameters for a specific key
  def update_flow_param_key(key, param)
    flow_params_temp = JSON.parse(self.flow_params || '{}')
    flow_params_temp[key] = param
    self.flow_params = flow_params_temp
  end

  # Returns flow parameters for a spaecific key
  def get_flow_param_key(key)
    JSON.parse(self.flow_params || '{}')[key]
  end

  # Returns the source object class for job - located in ./sources/
  def source_object
    source || Source.find_by_classname("Libris")
  end


end


require 'nokogiri'

class Job < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  scope :active, -> {where(quarantined: false, deleted_at: nil)}
  Job.per_page = 4

  belongs_to :treenode
  has_many :job_activities

  validates :title, :presence => true
  validates :catalog_id, :presence => true
  validates :treenode_id, :presence => true
  validates :source, :presence => true
  validate :source_in_list
  validate :xml_validity
  attr_accessor :created_by

  after_create :create_log_entry

  def as_json(options = {})
    if options[:list]
      { 
        id: id,
        name: name,
        title: title,
        display: display,
        source_label: source_label,
        catalog_id: catalog_id,
        breadcrumb_string: treenode.breadcrumb(as_string: true),
        treenode_id: treenode_id
      }
    else
      super.merge({
        display: display,
        source_label: source_label,
        breadcrumb: treenode.breadcrumb(include_self: true),
        activities: job_activities
      })
    end
  end

  # Creates a JobActivity object for CREATE event
  def create_log_entry(event="CREATE", message="Activity has been created")
    entry = JobActivity.new(job_id: id, username: created_by, event: event, message: message)
    if !entry.save
      errors.add(:job_activities, "Log entry could not be created")
    end
  end

  # Switches status according to given Status object
  def switch_status(new_status)
    self.status = new_status.name
    create_log_entry("STATUS", new_status.name)
  end

  # Generate preferred display name if name works
  def display
    name ? "#{name} (#{title})" : title
  end

  # Retrieve source label from config
  def source_label
    Source.find_label_by_name(source)
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

  # Check if source is in list of configured sources
  def source_in_list
    if !Rails.application.config.sources.map { |x| x[:name] }.include?(source)
      errors.add(:source, "not included in list of valid sources")
    end
  end

  ########################


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
    Source.find_by_classname("Libris")
  end


end


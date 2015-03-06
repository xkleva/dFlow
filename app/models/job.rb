require 'nokogiri'
require "prawn/measurement_extensions"

class Job < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  scope :active, -> {where(quarantined: false, deleted_at: nil)}
  Job.per_page = 50

  belongs_to :treenode
  has_many :job_activities, :dependent => :destroy

  validates :id, :uniqueness => true
  validates :title, :presence => true
  validates :catalog_id, :presence => true
  validates :treenode_id, :presence => true
  validates :source, :presence => true
  validates :copyright, :inclusion => {:in => [true, false]}
  validates :status, :presence => true
  validate :source_in_list
  validate :status_in_list
  validate :xml_validity
  validates_associated :job_activities
  attr_accessor :created_by

  after_create :create_log_entry
  after_initialize :default_values

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

  def default_values
    self.status ||= 'waiting_for_digitizing'
  end

  def created_by_string
    created_by || 'not_set'
  end

  # Creates a JobActivity object for CREATE event
  def create_log_entry(event="CREATE", message="Activity has been created")
    entry = JobActivity.new(username: created_by_string, event: event, message: message)
    job_activities << entry
  end

  # Switches status according to given Status object
  def switch_status(new_status)
    self.status = new_status.name
    self.create_log_entry("STATUS", new_status.name)
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
    if !APP_CONFIG["sources"].map { |x| x["name"] }.include?(source)
      errors.add(:source, "not included in list of valid sources")
    end
  end

  # Check if status is in list of configured sources
  def status_in_list
    if !APP_CONFIG["statuses"].map { |x| x["name"] }.include?(status)
      errors.add(:status, "#{status} not included in list of valid statuses")
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

  # Returns a legible title string in an illegible manner
  def title_string
    (title[/^(.*)\s*\/\s*$/,1] || title).strip
  end

  # Generates a display title used in lists primarily
  def display
    title_trunc = title_string.truncate(50, separator: ' ')
    display = name.present? ? name : title_trunc
    if !ordinals.blank?
      display += " (#{ordinals})"
    else
      if !name.blank? && !title.blank?
        display += " (#{title_trunc})"
      end
    end
    display
  end

  # Returns a specific metadata value from key
  def metadata_value(key)
    metadata_hash[key.to_s]
  end

  # Returns all metadata as a hash
  def metadata_hash
    return {} if metadata.blank? || metadata == "null"
    @metadata_hash ||= JSON.parse(metadata)
  end

  # Returns ordinal data as a string representation
  def ordinals(return_raw = false)
    ordinal_data = []
    ordinal_data << ordinal_num(1) if ordinal_num(1)
    ordinal_data << ordinal_num(2) if ordinal_num(2)
    ordinal_data << ordinal_num(3) if ordinal_num(3)
    return ordinal_data if return_raw
    ordinal_data.map { |x| x.join(" ") }.join(", ")
  end

  # Returns an ordnial array for given key
  def ordinal_num(num)
    key = metadata_value("ordinal_#{num}_key")
    value = metadata_value("ordinal_#{num}_value")
    return nil if key.blank? || value.blank?
    [key, value]
  end

  # Generates a work order pdf
  def create_pdf
    PdfHelper.create_work_order(self)
  end


end


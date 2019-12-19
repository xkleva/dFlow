require 'nokogiri'
require "prawn/measurement_extensions"
require 'httparty'

class Job < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  scope :active, -> {where(quarantined: false, deleted_at: nil)}
  Job.per_page = 50

  # RELATIONS
  belongs_to :treenode
  belongs_to :flow
  has_many :job_activities, :dependent => :destroy
  has_many :publication_logs, :dependent => :destroy
  has_many :flow_steps, -> {where(aborted_at: nil)}, :dependent => :destroy

  # BEFORE VALIDATION
  before_validation :set_treenode_ids

  # VALIDATIONS
  validates :id, :uniqueness => true
  validates :title, :presence => true
  validates :catalog_id, :presence => true
  validates :treenode_id, :presence => true
  validates :source, :presence => true
  validates :flow, :presence => true
  validate :source_in_list
  validates :copyright, :inclusion => {:in => [true, false]}
  validate :xml_validity
  validate :validate_flow
  validates_associated :job_activities

  # AFTER VALIDATION
  after_validation :init_flow_parameters

  # AFTER CREATE
  after_create :create_log_entry
  after_create :create_flow_steps

  # ACCESSORS
  attr_accessor :created_by
  attr_accessor :message
  attr_accessor :nolog # Flag, set to true to inactivate job activity creation

  def as_json(options = {})
    if !id
      json = {
        name: name,
        title: title
      }
    elsif options[:list]
      json = {
        id: id,
        name: name,
        title: title,
        display: display,
        source_label: source_label,
        catalog_id: catalog_id,
        breadcrumb_string: treenode_breadcrumb(as_string: true),
        treenode_id: treenode_id,
        quarantined: quarantined,
        main_status: main_status,
        is_processing: is_processing?,
        status: flow_step ? flow_step.description : "",
        comment: comment,
        object_info: object_info
      }
    else
      json = super.merge({
        display: display,
        source_label: source_label,
        breadcrumb: treenode_breadcrumb(include_self: true),
        activities: job_activities.as_json,
        metadata: metadata_hash,
        source_link: source_link,
        package_metadata: package_metadata_hash,
        main_status: main_status,
        files: files_list,
        is_periodical: is_periodical,
        status: flow_step ? flow_step.description : "",
        flow_step: flow_step,
        flow_steps: flow_steps,
        publication_logs: publication_logs,
        package_name: package_name,
        flow: flow,
        flow_parameters: flow_parameters_hash
        })
    end

    return json
  end

  def validate_flow
    if flow.present? && !flow.valid?
      flow.errors.full_messages.each do |msg|
        errors.add(:flow, msg)
      end
    end
  end

  def treenode_breadcrumb(params)
    return nil if !treenode
    treenode.breadcrumb(params)
  end

  def set_treenode_ids
    self.parent_ids = treenode.parent_ids if treenode
    true
  end

  # Sets quarantine flag for job
  def quarantine!(msg:)
    return if self.quarantined
    self.quarantined = true
    self.save(validate: false)
    create_log_entry("QUARANTINE", msg)
  end

  # Unsets quarantine flag for job
  def unquarantine!(step_nr:, recreate_flow: false)
    return if !self.quarantined
    self.update_attribute('quarantined', false)
    if recreate_flow
      flow.apply_flow(job: self, step_nr: step_nr)
    else
      reset_flow_steps(step_nr: step_nr)
    end
    create_log_entry("UNQUARANTINE","_UNQUARANTINED")
  end

  # Moves job to given flow step
  def new_flow_step!(step_nr:)
    old_flow_step_string = self.flow_step ? self.flow_step.info_string : ""
    reset_flow_steps(step_nr: step_nr)
    create_log_entry("FLOW_STEP", "Old: #{old_flow_step_string} New: #{self.flow_step.info_string}")
  end

  # Mark job as deleted
  def delete
    self.update_attribute(:deleted_at, Time.now)
  end

  # Check if job is deleted
  def deleted?
    deleted_at.present?
  end

  def created_by
    @created_by || 'not_set'
  end

  # Creates a JobActivity object for CREATE event
  def create_log_entry(event="CREATE", message="_ACTIVITY_CREATED")
    Rails.logger.info("username: #{created_by}, event: #{event}, message: #{message}")
    entry = JobActivity.new(username: created_by, event: event, message: message)
    job_activities << entry
    self.save
  end

  # Retrieve source label from config
  def source_label
    Source.find_label_by_name(source)
  end
  def get_publication_log_entry entry_type
    log_entry = publication_logs.where(publication_type: entry_type).first
    if log_entry
      return log_entry.comment
    end
    return nil
  end

  # Combine selected metadata into a single string to use in search_title
  def generate_search_title_metadata_string
    ord = ordinals(true)
    chron = chrons(true)
    ord_string = ord.map { |x| x.join(" ")}.compact.join(" ")
    chron_string = chron.map { |x| x.join(" ")}.compact.join(" ")
    [ord_string, chron_string].compact.join(" ")
  end

  # Generate the string to be stored in search_title
  def generate_search_title_string
    author_norm = author.blank? ? "" : author.norm
    name_norm = name.blank? ? "" : name.norm
    [
     title.norm,
     author_norm,
     name_norm,
     catalog_id.to_s,
     self.id.to_s,
     generate_search_title_metadata_string.norm
     ].compact.join(" ")
   end

  # Create search_title from title
  def build_search_title
    self.update_attribute(:search_title, generate_search_title_string)
  end

  # Generate search_titles for all jobs where it is missing
  def self.index_jobs
    Job.where(search_title: nil).each do |job|
      job.build_search_title
    end
  end

  ###VALIDATION METHODS###
  def xml_valid?(xml)
    test=Nokogiri::XML(xml)
    test.errors.empty?
  end

  # Checks validity
  def xml_validity
    errors.add(:xml, "XML must be valid") unless xml_valid?(xml)
  end

  # Check if source is in list of configured sources
  def source_in_list
    if !SYSTEM_DATA["sources"].map { |x| x["name"] }.include?(source)
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

  # Updates metadata for a specific key
  def update_package_metadata_key(key, metadata)
    metadata_temp = JSON.parse(self.package_metadata || '{}')
    metadata_temp[key] = metadata
    self.package_metadata = metadata_temp.to_json
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
    Source.find_by_name(source)
  end

  # Returns link to source if applicatble
  def source_link
    return source_object.try(:source_link, catalog_id)
  end

  # Returns a legible title string in an illegible manner
  def title_string
    (title[/^(.*)\s*\/\s*$/,1] || title).strip
  end

  # Generates a display title used in lists primarily
  def display
    title_trunc = title_string.truncate(85, separator: ' ')
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

  # Returns all package_metadata as a hash
  def package_metadata_hash
    return {} if package_metadata.blank? || package_metadata == "null"
    @package_metadata_hash ||= JSON.parse(package_metadata)
  end

  # Returns all package_metadata as a hash
  def flow_parameters_hash
    return {} if flow_parameters.blank? || flow_parameters == "null"
    @flow_parameters_hash ||= JSON.parse(flow_parameters)
    return @flow_parameters_hash
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

  # Returns an ordinal array for given key
  def ordinal_num(num)
    key = metadata_value("ordinal_#{num}_key")
    value = metadata_value("ordinal_#{num}_value")
    return nil if key.blank? || value.blank?
    [key, value]
  end

  # Returns chronological data as a string representation
  def chrons(return_raw = false)
    chron_data = []
    chron_data << chron_num(1) if chron_num(1)
    chron_data << chron_num(2) if chron_num(2)
    chron_data << chron_num(3) if chron_num(3)
    return chron_data if return_raw
    chron_data.map { |x| x.join(" ") }.join(", ")
  end

  # Returns an chronological array for given key
  def chron_num(num)
    key = metadata_value("chron_#{num}_key")
    value = metadata_value("chron_#{num}_value")
    return nil if key.blank? || value.blank?
    [key, value]
  end

  # Generates a work order pdf
  def create_pdf
    PdfHelper.create_work_order(self)
  end

  def package_name
    return sprintf(APP_CONFIG['package_name'], id)
  end

  def package_dir
    return sprintf(APP_CONFIG['package_dir'], id / APP_CONFIG['dir_size'])
  end

  # Restarts job by setting status and moving files
  def restart(recreate_flow: false)
    Job.transaction do
      if recreate_flow
        flow.apply_flow(job: self, step_nr: nil)
      else
        reset_flow_steps
      end
      flow.folder_paths_array.each do |folder_path|
        DfileApi.move_to_trash(source_dir: Job.substitute_parameters(string: folder_path, job_variables: self.variables, flow_variables: self.flow_parameters_hash))
      end
      self.update_attribute('quarantined', false) if quarantined
      create_log_entry("RESTART", message)
      save!
    end
  end

  # Returns a limited number of main statuses based on current status
  # Valid values: ["DONE", "WAITING_FOR_ACTION", "PROCESSING", "ERROR"]
  def main_status
    return "ERROR" if is_error?
    return "NOT_STARTED" if is_start?
    return "DONE" if is_done?
    return "WAITING_FOR_ACTION" if is_waiting_for_action?
    return "PROCESSING" if is_processing? || is_pending?
  end

  def is_start?
    state == "START"
  end

  def is_error?
    quarantined
  end

  def is_done?
    state == "FINISH"
  end

  def is_waiting_for_action?
    state == "ACTION"
  end

  def is_processing?
    return false if !flow_step
    return true if state == "WAITFOR"
    return true if state == "PROCESS" && flow_step.is_active? && flow_step.running?
    false
  end

  def is_pending?
    return false if !flow_step
    state == "PROCESS" && flow_step.is_active? && flow_step.pending?
  end

  # Returns a list of all files in job package
  def files_list
    files_list = []
    flow.folder_paths_array.each do |folder_path|
      folder_path = Job.substitute_parameters(string: folder_path, job_variables: self.variables, flow_variables: self.flow_parameters_hash)
      children = DfileApi.list_files(source_dir: folder_path)
      if children.present?
        files_list << {name: folder_path, children: DfileApi.list_files(source_dir: folder_path)}
      end
    end
    return files_list
  end

  # Returns true if job is a subset of a periodical
  def is_periodical
    return source_object.try(:is_periodical, metadata_value('type_of_record'))
  end

  def set_current_flow_step(flow_step)
    @flow_step = nil
    self.update_attribute('current_flow_step', flow_step.step)
    self.update_attribute('state', flow_step.main_state)
  end

  # Returns current flow step object
  def flow_step
    flow_steps.find { |x| x.step == current_flow_step }
  end

   # Creates flow_steps for flow
  def create_flow_steps
    @flow_step = nil
    if !flow.apply_flow(job: self, step_nr: self.current_flow_step)
      raise StandardError, "Could not create flow for job"
    end
    self.reload
  end

  def init_flow_parameters
    if self.flow.present?
      self.flow_parameters = flow.parameters_hash.merge(flow_parameters_hash).to_json
    end
  end

  # Changes the flow, aborts all previous flow steps and creates new ones
  def change_flow(flow_name: nil, step_nr: nil, flow_id: nil)
    @flow_step = nil
    if flow_name || flow_id
      if flow_name
        flow = Flow.where(name: flow_name).first
        if !flow
          raise StandardError, "No flow found with name #{flow_name}"
        end
      elsif flow_id
        flow = Flow.find(flow_id)
        if !flow
          raise StandardError, "No flow found with id #{flow_id}"
        end
      end
      if !flow.valid?
        raise StandardError, "Flow is invalid: #{flow_name} #{flow.errors.full_messages.inspect}"
      end
      self.update_attribute('flow_id', flow.id)
      self.update_attribute('flow_parameters', flow_parameters_hash.merge(flow.parameters_hash).to_json)
    else
      flow = self.flow
    end

    if step_nr
      self.update_attribute('current_flow_step', step_nr)
    else
      self.update_attribute('current_flow_step', flow.first_step['step'])
    end
    create_flow_steps
    self.update_attribute('state', flow_step.main_state)
  end

  # Sets jobs to finished
  def finish_job
    @flow_step = nil
    self.update_attribute('current_flow_step', flow.last_step)
    self.update_attribute('state', 'FINISH')
  end

  def page_count
    package_metadata_hash['image_count'] || -1
  end

  # Resets flow steps from step_nr and sets earlier steps as done.
  def reset_flow_steps(step_nr: nil)
    @flow_step = nil
    if step_nr
      flow_step = flow_steps.where(step: step_nr).first
      if !flow_step
        raise StandardError, "There is no flow step with number #{step_nr}"
      end
    else
      flow_step = first_flow_step
      if !flow_step
        raise StandardError, "Couldn't find the first flow step for job"
      end
    end

    flow_steps.each do |step|
      if step.is_before?(flow_step.step)
        step.force_finish!
      end

      if step.is_after?(flow_step.step) || step.is_equal?(flow_step.step)
        step.reset!
      end

      if step.is_equal?(flow_step.step)
        step.enter!
      end
    end

    self.update_attribute('current_flow_step', flow_step.step)

  end

  # Returns the first flow step of the flow
  def first_flow_step
    flow_steps.where("params ILIKE '%\"start\":true%'").first
  end

  def recreate_flow(step_nr: nil)
    change_flow(flow_name: self.flow.name, step_nr: step_nr)
  end

  # Make % into %% for everything not on the format of %{variable} so
  # that parameters can contain % without causing error
  def self.escape_non_variable_substitutions(string)
    string.gsub(/%(^{[a-z0-9_-]}|%|[^{])/) do |x|
      x = "%%#{$1}" if $1[0..0] != "{"
      x = "%%" if $1 == "%"
      x
    end
  end

  # Substitutes defined variable names according to map
  def self.substitute_parameters(string:, require_value: false, job_variables:, flow_variables:)
    new_string = Job.escape_non_variable_substitutions(string)
    if require_value
      return new_string % job_variables.merge(flow_variables.symbolize_keys).reject {|key, value| value.blank?}
    else
      return new_string % job_variables.merge(flow_variables.symbolize_keys)
    end
  end

  def self.validatable_hash
    new_hash = {}
    Job.variables_hash(Job.new(id: 0)).each do |k,v|
      new_hash[k] = "undefined"
    end
    new_hash
  end

  def variables
    Job.variables_hash(self)
  end

  def self.variables_hash(job)
    {
      job_id: job.id,
      catalog_id: job.catalog_id,
      title: job.title,
      type_of_record: job.metadata_value('type_of_record'),
      page_count: job.page_count || '-1',
      package_name: job.package_name,
      package_dir: job.package_dir,
      copyright: job.copyright.to_s,
      copyright_protected: job.copyright.to_s,
      chron_1: job.metadata_value('chron_1_value') || 'undefined',
      chron_2: job.metadata_value('chron_2_value') || 'undefined',
      chron_3: job.metadata_value('chron_3_value') || 'undefined',
      ordinality_1: job.metadata_value('ordinal_1_value') || 'undefined',
      ordinality_2: job.metadata_value('ordinal_2_value') || 'undefined',
      ordinality_3: job.metadata_value('ordinal_3_value') || 'undefined',
      gupea_url: job.get_publication_log_entry('GUPEA') || 'undefined'
    }

  end
end


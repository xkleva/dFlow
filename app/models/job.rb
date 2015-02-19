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

  # Check if status is in list of configured sources
  def status_in_list
    if !Rails.application.config.statuses.map { |x| x[:name] }.include?(status)
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

  # Generates a work order pdf for job
  def create_pdf
    md_value = 8

    pdf = Prawn::Document.new :page_size=> 'A4', :margin=>[10.send(:mm), 20.send(:mm), 12.7.send(:mm), 20.send(:mm)]

    pdf.move_down 2.7.send(:mm)

    pdf.text "Fjärrlån", :size=>24, :style=>:bold
    pdf.move_down md_value*2

    pdf.text "132", :size=>16

    pdf.font_size = 11

    pdf.move_down (15.send(:mm) + md_value)

    pdf.text "Handläggande enhet", :style=>:bold
    pdf.text " "
    pdf.move_down md_value*2

    pdf.font_size = 14

    pdf.bounding_box([0, pdf.cursor], :width => (126).send(:mm)) do
      pdf.text "Titel", :style=>:bold
      pdf.text "#{self.title} "
      pdf.move_down md_value

      pdf.text "Författare", :style=>:bold
      pdf.text "#{self.author} "
      pdf.move_down md_value

      #pdf.transparent(0.5) { pdf.stroke_bounds}
    end

    pdf.move_down md_value*2
    top_line_cursor = pdf.cursor

    pdf.bounding_box([0, pdf.cursor], :width => 82.send(:mm)) do

      #stroke_bounds
      pdf.font_size = 11

      #my_cursor = pdf.cursor
      pdf.text "Tidskriftstitel", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "ISSN/ISBN", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "Publiceringsår", :style=>:bold
      pdf.text " "
      pdf.move_down md_value
      #pdf.transparent(0.8) { pdf.stroke_bounds}
      upper_right_col = pdf.cursor
    end

    pdf.bounding_box([87.send(:mm), top_line_cursor], :width => 82.send(:mm)) do
      pdf.text "Volym", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "Nummer", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "Sidor", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      #pdf.transparent(0.5) { pdf.stroke_bounds}
      upper_left_col = pdf.cursor
    end

    pdf.move_down md_value*2
    pdf.line [0, pdf.cursor], [pdf.bounds.right, pdf.cursor]
    pdf.stroke
    pdf.move_down md_value*2

    middle_line_cursor = pdf.cursor

    pdf.bounding_box([0, middle_line_cursor], :width => 82.send(:mm)) do
      pdf.text "Namn", :style=>:bold
      pdf.text "#{self.name} "
      pdf.move_down md_value

      pdf.text "Adress", :style=>:bold
      pdf.text "123 "
      pdf.text "234 "
      pdf.text "345 "
      pdf.move_down md_value

      pdf.text "Telefonnummer", :style=>:bold
      pdf.text "1232354456 "
      pdf.move_down md_value

      pdf.text "E-postadress", :style=>:bold
      pdf.text "awdsefgrdgdrgrdg@.awda "
      pdf.move_down md_value

      pdf.text "Lånekortsnummer", :style=>:bold
      pdf.text "123142354245346 "
      pdf.move_down md_value

      pdf.text "Kundtyp", :style=>:bold
      pdf.text "type "
      pdf.move_down md_value

      pdf.text "Faktureringsadress", :style=>:bold
      pdf.text "awdawdawd "
      pdf.text "adawdawdawdaw "
      pdf.text "awdawdawd "
      pdf.text "awd "
      pdf.move_down md_value

      #pdf.transparent(0.5) { pdf.stroke_bounds}
      lower_right_col = pdf.cursor
    end

    pdf.bounding_box([87.send(:mm), middle_line_cursor], :width => 82.send(:mm)) do

      pdf.text "Ansvarsnummer och beställarid", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "Ej aktuell efter", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "Beställningstyp", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "Leveransalternativ", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      pdf.text "Kommentar", :style=>:bold
      pdf.text " "
      pdf.move_down md_value

      #pdf.transparent(0.5) { pdf.stroke_bounds}
      lower_left_col = pdf.cursor
    end

    pdf.move_cursor_to (7).send(:mm)
    pdf.line [0, pdf.cursor], [pdf.bounds.right, pdf.cursor]
    pdf.stroke

    pdf.move_cursor_to (5).send(:mm)

    pdf.text "Beställare: #{name}"
    pdf.number_pages "<page>(<total>)", {:at=>[pdf.bounds.right - 20, 12], :size=>10}

    pdf.render
  end


end


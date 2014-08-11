class Job < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  belongs_to :source
  before_save :generate_search_title
  before_validation :generate_source_id

  validates :status_id, :presence => true
  validates :title, :presence => true
  validates :catalog_id, :presence => true
  validates :source_id, :presence => true
  validate :xml_validity

  attr_accessor :failed
  attr_accessor :metadata
  attr_accessor :new_copyright
  attr_accessor :import_rownr
  attr_accessor :copyright_value_exp


  def self.search(searchterm)
    Job.where("(lower(title) LIKE ?) OR (lower(name) LIKE ? ) OR (lower(author) LIKE ?) OR (lower(search_title) LIKE ?) OR (id = ?) OR (catalog_id = ?)",
      "%#{searchterm.downcase}%",
      "%#{searchterm.downcase}%",
      "%#{searchterm.downcase}%",
      "%#{searchterm.downcase}%",
      searchterm[/^\d+$/] ? searchterm.to_i : nil,
      searchterm[/^\d+$/] ? searchterm.to_i : nil)
  end

  def source_object
    source || Source.find_by_classname("Libris")
  end

  def xml_valid?(xml)
    test=Nokogiri::XML(xml)
    test.errors.empty?
  end

  def xml_validity
    errors.add(:base, "Marc must be valid xml") unless xml_valid?(xml)
  end

  def created_by_present?
    !created_by.nil?
  end

  def note
    note_md = job_metadata.where(:key => "note")
    return nil if note_md.blank?
    note_md.first.value
  end

  def type_of_record
    type_md = job_metadata.where(:key => "type_of_record")
    return "am" if type_md.blank? # Default to am
    type_md.first.value
  end

  def display_title
    title_trunc = title.truncate(DigFlow::Application.config.text[:truncate], separator: ' ')
    display = name || title_trunc
    if !ordinals.blank?
      display += " (#{ordinals})"
    else
      if !name.blank? && !title.blank?
        display += " (#{title_trunc})"
      end
    end
    display
  end

  def ordinals_and_chronologicals
    pt = ''
    if !ordinals.blank?
      pt += "(#{ordinals})"

      if !chronologicals.blank?
        pt += " (#{chronologicals})"
      end
    elsif !chronologicals.blank?
      pt += "(#{chronologicals})"
    end
    pt
  end



  def ordinals(return_raw = false)
    ordinal_metadata = Hash[job_metadata
      .where(:key => [1,2,3]
        .map{|x| ["ordinal_#{x}_key", "ordinal_#{x}_value"]}.flatten)
      .map {|x| [x.key, x.value]}]
    ordinal_data = []
    ordinal_data << ordinal_num(1, ordinal_metadata) if ordinal_num(1, ordinal_metadata)
    ordinal_data << ordinal_num(2, ordinal_metadata) if ordinal_num(2, ordinal_metadata)
    ordinal_data << ordinal_num(3, ordinal_metadata) if ordinal_num(3, ordinal_metadata)
    return ordinal_data if return_raw
    ordinal_data.map { |x| x.join(" ") }.join(", ")
  end

  def ordinal_num(num, ordinal_metadata)
    key = ordinal_metadata["ordinal_#{num}_key"]
    value = ordinal_metadata["ordinal_#{num}_value"]
    return nil if key.blank? || value.blank?
    [key, value]
  end

  def chronologicals(return_raw = false)
    chronological_metadata = Hash[job_metadata
      .where(:key => [1,2,3]
        .map{|x| ["chron_#{x}_key", "chron_#{x}_value"]}.flatten)
      .map {|x| [x.key, x.value]}]
    chronological_data = []
    chronological_data << chronological_num(1, chronological_metadata) if chronological_num(1, chronological_metadata)
    chronological_data << chronological_num(2, chronological_metadata) if chronological_num(2, chronological_metadata)
    chronological_data << chronological_num(3, chronological_metadata) if chronological_num(3, chronological_metadata)
    return chronological_data if return_raw
    chronological_data.map { |x| x.join(" ") }.join(", ")
  end

  def chronological_num(num, chronological_metadata)
    key = chronological_metadata["chron_#{num}_key"]
    value = chronological_metadata["chron_#{num}_value"]
    return nil if key.blank? || value.blank?
    [key, value]
  end

  def has_pdf?
    !!mets_pdf_file(false)
  end

  def get_pdf
    return nil unless has_pdf?
    File.open(mets_pdf_file(false), "rb")
  end

  def has_digitizing_begin?
    status.name == "waiting_for_digitizing_begin"
  end

  def waiting_for_quality_control?
    status.name == "waiting_for_quality_control_begin"
  end

  def is_done?
    status.name == "done"
  end

  def set_quarantine(note)
    event = Event.find_by_name("quarantine")
    event.run_event(self, 0, note)
    AlertMailer.quarantine_alert(self,note,nil, "quarantined").deliver #Send an alert email when system puts job in quarantine
  end

  def quarantine
    Quarantine.new
  end

  def unquarantine
    Unquarantine.new
  end

  def quarantine_id=(value)
    self.quarantined = true
  end

  def unquarantine_id=(value)
    self.quarantined = false
  end

  def as_json(opts)
    super.merge({
                  :metadata => metadata,
                  :import_rownr => import_rownr,
                  :copyright_value_exp => copyright_value,
                  :type_of_record => type_of_record,
                  :type_of_record_text => I18n.t("mets.structure."+type_of_record)
                })
  end

  # encode_with and init_with necessary for to_yaml to include @metadata
  def encode_with(coder)
    super
    coder['metadata'] = metadata
    coder['import_rownr'] = import_rownr
  end

  def init_with(coder)
    super
    @metadata = coder['metadata']
    self.import_rownr = coder['import_rownr']
    self
  end

  def copyright_value
    copyright || self.project.copyright_value
  end

  #returns the job's progress as a percentage integer, based on the current status compared to total amount of statuses
  def progress
    cnt_statuses = Status.where("selection_order is not null").count;
    cnt_status_progress = Status.where("selection_order is not null").where("selection_order <= " + self.status.selection_order.to_s).count
    return 100*(cnt_status_progress.to_f/cnt_statuses.to_f)
  end

  def generate_search_title
    self.search_title = source_object.search_title(self)
  end

  def generate_source_id
    self.source_id = source_object.id unless self.source_id
  end

  # Updates metadata for a specific key
  def update_metadata_key(key, metadata)
    metadata_temp = JSON.parse(self.metadata_json || '{}')
    metadata_temp[key] = metadata

    self.metadata_json = metadata_temp.to_json
  end
end


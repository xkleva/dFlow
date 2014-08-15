require 'nokogiri'

class Job < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )} #Hides all deleted jobs from all queries, works as long as no deleted jobs needs to be visualized in dFlow
  scope :active, -> {where(quarantined: false, deleted_at: nil)}

  has_many :entries
  belongs_to :source
  before_save :generate_search_title
  before_validation :generate_source_id

  validates :title, :presence => true
  validates :catalog_id, :presence => true
  validates :source_id, :presence => true
  validate :xml_validity


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

###OLD METHODS###
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

def chronological_num(num, chronological_metadata)
  key = chronological_metadata["chron_#{num}_key"]
  value = chronological_metadata["chron_#{num}_value"]
  return nil if key.blank? || value.blank?
  [key, value]
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
      :import_rownr => import_rownr,
      :copyright_value_exp => copyright_value,
      :type_of_record => type_of_record,
      :type_of_record_text => I18n.t("mets.structure."+type_of_record)
      })
  end

  def copyright_value
    copyright || self.project.copyright_value
  end

  def generate_search_title
    #self.search_title = source_object.search_title(self)
  end

  def generate_source_id
    self.source_id = source_object.id unless self.source_id
  end

  
end


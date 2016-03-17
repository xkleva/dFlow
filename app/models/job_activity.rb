class JobActivity < ActiveRecord::Base
  default_scope -> {order('created_at DESC')}
  belongs_to :job
  validates :job, :presence => true
  validates :username, :presence => true
  validates :event, :presence => true
  validate :event_in_list

  # Check if event is in list of configured events
  def event_in_list
    if !SYSTEM_DATA["events"].map { |x| x["name"] }.include?(event)
      errors.add(:event, "not included in list of valid events")
    end
  end

end

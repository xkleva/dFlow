class JobActivity < ActiveRecord::Base
  belongs_to :job
  validates :job, :presence => true
  validates :username, :presence => true
  validates :event, :presence => true
  validate :event_in_list

  # Check if event is in list of configured events
  def event_in_list
    if !Rails.application.config.events.map { |x| x[:name] }.include?(event)
      errors.add(:event, "not included in list of valid events")
    end
  end

end

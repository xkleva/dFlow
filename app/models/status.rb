class Status
  attr_accessor :name
  
  def initialize(status_hash)
    @name = status_hash[:name]
    @next_status_name = status_hash[:next_status]
  end
  # Return status object
  def self.find_by_name(name)
    Status.new(Rails.application.config.find{|x| x[:name] == name})
  end

  # Returns next status object
  def next_status
    Status.find_by_name(@next_status_name)
  end



end
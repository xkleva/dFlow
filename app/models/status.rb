class Statuss
  attr_accessor :name, :state

  def initialize(status_hash)
    @name = status_hash["name"]
    @next_status_name = status_hash["next_status"]
    @previous_status_name = status_hash["previous_status"]
    @state = status_hash["state"]
  end
  # Return status object
  def self.find_by_name(name)
    Status.new(APP_CONFIG["statuses"].find{|x| x["name"] == name})
  end

  def self.find_start_status
    Status.new(APP_CONFIG["statuses"].find{|x| x["state"] == "START"})
  end

  def self.find_finish_status
    Status.new(APP_CONFIG["statuses"].find{|x| x["state"] == "FINISH"})
  end

  # Returns array of status names for given state
  def self.status_by_state(state)
    APP_CONFIG["statuses"].select{|x| x["state"] == state}.map{|x| x["name"]}
  end

  def self.all_states
    APP_CONFIG["statuses"].map{|x| x["state"]}.uniq
  end

  # Returns next status object
  def next_status
    Status.find_by_name(@next_status_name)
  end

  # Returns previous status object
  def previous_status
    if @previous_status_name
      Status.find_by_name(@previous_status_name)
    else
      nil
    end
  end

end
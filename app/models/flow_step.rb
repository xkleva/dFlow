class FlowStep < ActiveRecord::Base
  belongs_to :job

  validates :step, uniqueness: {scope: [:job_id, :aborted_at]}
  validates :step, numericality: { only_integer: true }

  validates :process, presence: true
  validate :process_in_list
  validate :validate_params

  # Returns true if step has not been aborted
  def is_active?
    aborted_at.nil?
  end

  # Returns error if mandatory params are missing
  def validate_params
    if process_object && process_object["required_params"]
      process_object["required_params"].each do |param|
        if !params_hash.has_key?(param)
          errors.add(:params, "Missing mandatory param #{param}")
        end
      end
    end
  end

  # Check if status is in list of configured sources
  def process_in_list
    if !APP_CONFIG["processes"].map { |x| x["code"] }.include?(process)
      errors.add(:process, "#{process} not included in list of valid statuses")
    end
  end

  def process_object
    @process_object ||= APP_CONFIG["processes"].find { |x| x["code"] == process}
  end

  def params_hash
    # Returns all params as a hash
    return {} if params.blank? || params == "null"
    @params_hash ||= JSON.parse(params)
  end

end

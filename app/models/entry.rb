class Entry < ActiveRecord::Base
	scope :pending, -> {where(state: "PENDING")}
	scope :started, -> {where(state: "STARTED")}
	scope :done, -> {where(state: "DONE")}
	scope :find_for_process, ->(process_id) { joins(:workflow_step).where(workflow_steps: {process_id: process_id})}

	belongs_to :job
	belongs_to :flow_step
	validates_inclusion_of :state, :in => ["PENDING", "STARTED", "DONE"]

	def self.most_recent
		order('created_at DESC').limit(1).first
	end

	def self.oldest
		order('created_at ASC').limit(1).first
	end

end

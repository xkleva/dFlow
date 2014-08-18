class Flow < ActiveRecord::Base
	belongs_to :flow_step, :foreign_key => :start_position, :primary_key => :id
	validates :start_position, presence: true
end

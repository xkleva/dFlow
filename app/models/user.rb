class User < ActiveRecord::Base
	validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }, :if => :email_present?
	validates :username, :presence => true
	validates :username, :uniqueness => true
	validates :name, :presence => true

	def email_present?
		!email.nil?
	end

	def delete
		update_attribute(:deleted_at, Time.now)
	end
end

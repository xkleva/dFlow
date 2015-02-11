class User < ActiveRecord::Base
	validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }, :if => :email_present?
	validates :username, :presence => true
	validates :username, :uniqueness => true
	validates :name, :presence => true
	validates :role, :presence => true
	validate :role_valid

	# Validates that role exists in config file
	def role_valid
		if Rails.application.config.user_roles.select{|role| role[:name] == self.role}.empty?
			errors.add(:role, "Role does not exist in config")
		end
	end

	def email_present?
		!email.nil?
	end

	def delete
		update_attribute(:deleted_at, Time.now)
	end
end

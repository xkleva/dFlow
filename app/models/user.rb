class User < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )}
  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }, :if => :email_present?
  validates :username, :presence => true
  validates :username, :uniqueness => {:scope => :deleted_at, :case_sensitive => false}
  validates :name, :presence => true
  validates :role, :presence => true
  validates :password, confirmation: true
  validate :role_valid
  DEFAULT_PASSWD_FILE = "#{Rails.root}/config/passwd"
  DEFAULT_TOKEN_EXPIRE = 1.day
  has_many :access_tokens
  before_save :encrypt_password

  def as_json(options = {})
    data = super
    data.delete("password")
    data
  end
  
  def encrypt_password
    # Only encrypt password if it exists and is not already encrypted
    if self.password.present? && !BCrypt::Password.valid_hash?(self.password)
      self.password = BCrypt::Password.create(self.password)
    end
  end
  
  # Validates that role exists in config file
  def role_valid
    if (APP_CONFIG["user_roles"]+SYSTEM_DATA["user_roles"]).select{|role| role["name"] == self.role}.empty?
      errors.add(:role, "Role does not exist in config")
    end
  end

  def email_present?
    !email.nil?
  end

  def delete
    update_attribute(:deleted_at, Time.now)
  end

  def deleted?
    deleted_at.present?
  end

  # Clear all tokens that have expired
  def clear_expired_tokens
    access_tokens.where("token_expire < ?", Time.now).destroy_all
  end

  # Returns role hash from config file
  def role_object
    (APP_CONFIG["user_roles"]+SYSTEM_DATA["user_roles"]).select{|role| role["name"] == self.role}.first
  end

  # Checks if users role has given right value
  def has_right?(right_value)
    role_object["rights"].include? right_value
  end

  # First clear all invalid tokens. Then look for our provided token.
  # If we find one, we know it is valid, and therefor update its validity
  # further into the future
  def validate_token(provided_token, extend_expire = true)
    clear_expired_tokens
    token_object = access_tokens.find_by_token(provided_token)
    return false if !token_object
    if extend_expire
      token_object.update_attribute(:token_expire, Time.now + DEFAULT_TOKEN_EXPIRE)
    end
    true
  end

  # Authenticate user against password sources
  def authenticate(provided_password, force_authenticate=false)
    if force_authenticate
      token_object = generate_token
      return token_object.token
    end

    auth_status = authenticate_local(provided_password)
    auth_status
  end

  # Authenticate against passwords in database
  def authenticate_local(provided_password)
    if self.password.blank?
      return false
    end
    pass = BCrypt::Password.new(self.password)
    if(pass == provided_password)
      token_object = generate_token
      return token_object.token
    end
    false
  end

  # Generate a random token
  def generate_token
    token_hash = SecureRandom.hex
    token_hash.force_encoding('utf-8')
    access_tokens.create(token: token_hash, token_expire: Time.now + DEFAULT_TOKEN_EXPIRE)
  end
  
  # Read all users from input file and create users that do not already exist
  # This step does nothing if supplied file is missing
  def self.create_missing_users_from_file(filename = DEFAULT_PASSWD_FILE)
    return if !File.exist?(filename)
    File.open(filename, "r:utf-8") do |file|
      file.each_line do |line| 
        line.chomp!
        username,passhash,fullname,email,role = line.split(/:/)
        user = User.find_by_username(username)
        
        if user
          # Check if password field is populated, otherwise write the one from the file
          if user.password.blank?
            user.update_attribute(:password, passhash)
          end
        else
          User.create(username: username, name: fullname, email: email, role: role)
        end
      end
    end
  end
end


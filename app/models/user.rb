class User < ActiveRecord::Base
  validates :email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }, :if => :email_present?
  validates :username, :presence => true
  validates :username, :uniqueness => true
  validates :name, :presence => true
  validates :role, :presence => true
  validate :role_valid
  DEFAULT_PASSWD_FILE = "#{Rails.root}/config/passwd"
  DEFAULT_TOKEN_EXPIRE = 1.day
  has_many :access_tokens

  # Validates that role exists in config file
  def role_valid
    if APP_CONFIG["user_roles"].select{|role| role["name"] == self.role}.empty?
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
    APP_CONFIG["user_roles"].select{|role| role["name"] == self.role}.first
  end

  # Checks if users role has given right value
  def has_right?(right_value)
    role_object["rights"].include? right_value
  end

  # First clear all invalid tokens. Then look for our provided token.
  # If we find one, we know it is valid, and therefor update its validity
  # further into the future
  def validate_token(provided_token)
    clear_expired_tokens
    token_object = access_tokens.find_by_token(provided_token)
    return false if !token_object
    token_object.update_attribute(:token_expire, Time.now + DEFAULT_TOKEN_EXPIRE)
    true
  end

  # Authenticate user against password sources
  def authenticate(provided_password)
    user_file_data = authenticate_get_local_user
    auth_status = false
    if user_file_data
      auth_status = authenticate_local(user_file_data, provided_password)
    else
      if APP_CONFIG["external_auth"]
        auth_status = authenticate_external(provided_password)
      end
    end
    auth_status
  end

  # Authenticate against external server
  def authenticate_external(provided_password)
    uri = URI(APP_CONFIG["external_auth_url"] + "/" + self.username)
    params = { :password => provided_password}
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP.get_response(uri)
    json_response = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
    if(json_response["auth"]["yesno"])
      token_object = generate_token
      return token_object.token
    end
    false
  end

  # Authenticate against local passwd file
  # If we run in test environment, read filename from Rails.cache to reach a test passwd file
  # instead of the system one.
  def authenticate_local(user_file_data, provided_password)
    if self.username == user_file_data[:username]
      pass = BCrypt::Password.new(user_file_data[:passhash])
      if(pass == provided_password)
        token_object = generate_token
        return token_object.token
      end
    end
    false
  end

  # Check if user exists at all in local file
  def authenticate_get_local_user(filename = DEFAULT_PASSWD_FILE)
    if Rails.env == "test"
      filename = Rails.cache.read("test_passwd_filename")
    end
    return false if !filename || !File.exist?(filename)
    File.open(filename, "r:utf-8") do |file|
      file.each_line do |line| 
        line.chomp!
        username,passhash,_fullname,_email,_role = line.split(/:/)
        if self.username == username
          return {username: username, passhash: passhash }
        end
      end
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
        username,_passhash,fullname,email,role = line.split(/:/)
        next if User.find_by_username(username)
        User.create(username: username, name: fullname, email: email, role: role)
      end
    end
  end
end


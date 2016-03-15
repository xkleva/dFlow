# Define config location
APP_CONFIG_FILE_LOCATION = "#{Rails.root}/config/config_full.yml"
DATABASE_CONFIG_FILE_LOCATION = "#{Rails.root}/config/database.yml"

# If in test environment, generate file. Otherwise it should already exist.
if Rails.env == 'test' || Rails.env == 'development'
  #ConfigLoader.generate_file(base_file_path: "#{Rails.root}/config/app-config.yml", environment: Rails.env)
end

main_config = YAML.load_file(APP_CONFIG_FILE_LOCATION)

APP_CONFIG = main_config || {}

require 'pp'
pp APP_CONFIG
if APP_CONFIG['is_setup']
  #Generate database.yml from APP_CONFIG['db']
  db_hash = {}
  db_hash[Rails.env] = APP_CONFIG['db'].dup
  db_hash[Rails.env]['adapter'] = 'postgresql'
  db_hash[Rails.env]['encoding'] = 'unicode'
  config_file = File.open(DATABASE_CONFIG_FILE_LOCATION, "w:utf-8") do |file|
    file.write(db_hash.to_yaml)
  end
else
  Rails.application.middleware.tap do |middleware|
    middleware.delete ActiveRecord::Migration::CheckPending
    middleware.delete ActiveRecord::ConnectionAdapters::ConnectionManagement
    middleware.delete ActiveRecord::QueryCache
  end
end
# Read all users from passwd file and create users that do not already exist
#if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users') # Checks if table exists to be able to migrate a new db
#  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
#end

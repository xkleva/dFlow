# Define config location
APP_CONFIG_FILE_LOCATION = "#{Rails.root}/config/config_full.yml"
APP_CONFIG_TEST_FILE_LOCATION = "#{Rails.root}/config/config_full_test.yml"
SYSTEM_DATA_FILE_LOCATION = "#{Rails.root}/config/system_data.yml"
DATABASE_CONFIG_FILE_LOCATION = "#{Rails.root}/config/database.yml"

main_config = YAML.load_file(SYSTEM_DATA_FILE_LOCATION)
SYSTEM_DATA = main_config || {}

if Rails.env == 'test'
  main_config = YAML.load_file(APP_CONFIG_TEST_FILE_LOCATION)
else
  main_config = YAML.load_file(APP_CONFIG_FILE_LOCATION)
end
APP_CONFIG = main_config || {}
require 'pp'
pp APP_CONFIG

if APP_CONFIG['_is_setup']
  pp "i setup"
  #Generate database.yml from APP_CONFIG['db']
  db_hash = {}
  db_hash[Rails.env] = APP_CONFIG['db'].dup
  db_hash[Rails.env]['adapter'] = 'postgresql'
  db_hash[Rails.env]['encoding'] = 'unicode'
  config_file = File.open(DATABASE_CONFIG_FILE_LOCATION, "w:utf-8") do |file|
    file.write(db_hash.to_yaml)
  end
  # Read all users from passwd file and create users that do not already exist
  if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users') # Checks if table exists to be able to migrate a new db
    User.create_missing_users_from_file("#{Rails.root}/config/passwd")
  end
else
  pp "ingen databas"
  Rails.application.middleware.tap do |middleware|
    middleware.delete ActiveRecord::Migration::CheckPending
    middleware.delete ActiveRecord::ConnectionAdapters::ConnectionManagement
    middleware.delete ActiveRecord::QueryCache
  end
end

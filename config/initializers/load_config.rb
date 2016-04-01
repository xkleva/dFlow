# Define config location
APP_CONFIG_FILE_LOCATION = "#{Rails.root}/config/config_full.yml"
APP_CONFIG_TEST_FILE_LOCATION = "#{Rails.root}/config/config_full_test.yml"
SYSTEM_DATA_FILE_LOCATION = "#{Rails.root}/config/system_data.yml"

main_config = YAML.load_file(SYSTEM_DATA_FILE_LOCATION)
SYSTEM_DATA = main_config || {}

if Rails.env == 'test'
  main_config = YAML.load_file(APP_CONFIG_TEST_FILE_LOCATION)
else
  main_config = YAML.load_file(APP_CONFIG_FILE_LOCATION)
end
APP_CONFIG = main_config || {}

# Read all users from passwd file and create users that do not already exist
if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users') # Checks if table exists to be able to migrate a new db
  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
end

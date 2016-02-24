
# If in test environment, generate file. Otherwise it should already exist.
if Rails.env == 'test' || Rails.env == 'development'
  ConfigLoader.generate_file(base_file_path: "#{Rails.root}/config/app-config.yml", environment: Rails.env)
end

main_config = YAML.load_file("#{Rails.root}/config/config_full_#{Rails.env}.yml")

APP_CONFIG = main_config

# Read all users from passwd file and create users that do not already exist
if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users') # Checks if table exists to be able to migrate a new db
  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
end

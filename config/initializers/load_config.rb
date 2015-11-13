# Read config files and store applicable values in APP_CONFIG constant
main_config = YAML.load_file("#{Rails.root}/config/config.yml")
workflows_config = YAML.load_file("#{Rails.root}/config/workflows.yml")
if Rails.env == 'test'
  secret_config = YAML.load_file("#{Rails.root}/config/config_secret.test.yml")
  workflows_config = YAML.load_file("#{Rails.root}/config/workflows_test.yml")
else
  secret_config = YAML.load_file("#{Rails.root}/config/config_secret.yml")
end
APP_CONFIG = main_config.merge(secret_config).merge(workflows_config)

# Read all users from passwd file and create users that do not already exist
if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users') # Checks if table exists to be able to migrate a new db
  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
end

# Load QueueManager config

QUEUE_MANAGER_CONFIG = YAML.load_file("#{Rails.root}/config/queue_manager/queue_manager.yml")

METS_CONFIG = YAML.load_file("#{Rails.root}/config/queue_manager/processes/create_mets_package/mets_config.yml")

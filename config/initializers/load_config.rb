# Define config location
APP_CONFIG_FILE_LOCATION = "#{Rails.root}/config/config_full.yml"
APP_CONFIG_TEST_FILE_LOCATION = "#{Rails.root}/config/config_full_test.yml"
SYSTEM_DATA_FILE_LOCATION = "#{Rails.root}/config/system_data.yml"
LAST_COMMIT_FILE_LOCATION = "#{Rails.root}/last_commit.txt"

main_config = YAML.load_file(SYSTEM_DATA_FILE_LOCATION)
SYSTEM_DATA = main_config || {}

if Rails.env == 'test'
  main_config = YAML.load_file(APP_CONFIG_TEST_FILE_LOCATION)
else
  main_config = YAML.load_file(APP_CONFIG_FILE_LOCATION)
end

# Load commit file information, created with 'git log -1 > last_commit.txt'
version_data = {}
if File.file?(LAST_COMMIT_FILE_LOCATION)
  File.readlines(LAST_COMMIT_FILE_LOCATION).each do |line|
    key,value = line.split(' ',2)
    case key
    when 'commit'
      version_data['commit'] = value.strip
    when 'Author:'
      version_data['author'] = value.strip
    when 'Date:'
      version_data['date'] = value.strip
      version_data['version'] = DateTime.parse(value.strip).strftime('%FT%R')
    end
  end
end

VERSION_DATA = version_data
APP_CONFIG = main_config || {}

# Read all users from passwd file and create users that do not already exist
if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users')  && ActiveRecord::Base.connection.column_exists?('users', 'password')# Checks if table exists to be able to migrate a new db
  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
end


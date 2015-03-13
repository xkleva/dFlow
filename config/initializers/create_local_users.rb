# Read all users from passwd file and create users that do not already exist
#if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users') # Checks if table exists to be able to migrate a new db
#  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
#end

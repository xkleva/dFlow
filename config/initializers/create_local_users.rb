# Read all users from passwd file and create users that do not already exist
User.create_missing_users_from_file("#{Rails.root}/config/passwd")

# Read all users from passwd file and create users that do not already exist
if Rails.env != "test"
  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
end

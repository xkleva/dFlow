#!/usr/bin/env ruby

require_relative 'config/environment'
require 'pp'

# Read username and password from commandline, encrypt password and return
def read_credentials
  print "Username: "
  username = gets.chomp
  print "Password: "
  password = STDIN.noecho(&:gets).chomp
  puts ""
  print "Full name: "
  fullname = gets.chomp
  print "Email: "
  email = gets.chomp
  roles = APP_CONFIG["user_roles"].reject {|x| x["unassignable"]}.map {|x| x[:name]}
  print "Role (#{roles.join(", ")}): "
  role = gets.chomp
  encrypted_password = BCrypt::Password.create(password)
  return [username, encrypted_password, fullname, email, role]
end

# Write new credentials to file
def write_new_credentials(new_username, encrypted_password, new_fullname, new_email, new_role)
  user_exists = false
  lines = []
  filename = User::DEFAULT_PASSWD_FILE
  File.open(filename, "r:utf-8") do |file|
    lines = file.read.split(/\n/)
    lines.each.with_index do |line,i| 
      line.chomp!
      username,_passhash,_fullname,_email,_role = line.split(/:/)
      if new_username == username
        user_exists = true
        lines[i] = [username, encrypted_password, new_fullname, new_email, new_role].join(":")
      end
    end
  end
  if !user_exists
    lines << [new_username, encrypted_password, new_fullname, new_email, new_role].join(":")
  end
  File.open(filename, "w:utf-8") do |file| 
    file.write(lines.join("\n"))
  end
  if !user_exists
    puts "Restart Rails application to load new user"
  end
end

credentials = read_credentials
write_new_credentials(*credentials)

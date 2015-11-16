
# Read all users from passwd file and create users that do not already exist
if Rails.env != "test" && (ActiveRecord::Base.connection.table_exists? 'users') # Checks if table exists to be able to migrate a new db
  User.create_missing_users_from_file("#{Rails.root}/config/passwd")
end

# Load QueueManager config

class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
end

class ConfigLoader

  def self.load_config_structure(base_file_path:)

    base_file = Pathname.new(base_file_path)

    # Load app-config.yml file
    main_config = load_config_file(path: base_file, config_hash: {})

    # Load files from .d
    d_folder = Pathname.new("#{base_file.dirname.to_s}/#{base_file.basename('.*')}.d")

    if d_folder.exist? && d_folder.directory?
      files = d_folder.children.sort_by { |x| x.basename.to_s }
      files.each do |file|
        main_config = load_config_file(path: file, config_hash: main_config)
      end

      # Load test files if currently in test environment
      if Rails.env == 'test'
        files = d_folder.children.sort_by { |x| x.basename.to_s[/^(\d+)\./,1].to_i }.reverse
        files.each do |file|
          if file.basename.to_s.downcase.start_with?('test')
            main_config = load_config_file(path: file, config_hash: main_config, test_file: true)
          end
        end
      end
    else
      Rails.logger.info "There is no app-config-d directory, aborting"
    end

    return main_config

  end

  def self.load_config_file(path:, config_hash:, test_file: false)

    # Check if file exists
    if !path.exist?
      Rails.logger.info "Not loading #{path.to_s} as it doesn't seem to exist"
      return config_hash
    end

    # Check if file name starts with an alphanumerical character
    if (path.basename.to_s.first =~ /\A\p{Alnum}+\z/).nil?
      Rails.logger.debug "Not loading #{path.to_s} as it's starting with an illegal character"
      return config_hash
    end

    # Check if file is a test config
    if test_file
      if (!path.basename.to_s.downcase.start_with?('test'))
        Rails.logger.debug "Not loading #{path.to_s} as it is not a configuration file for test"
        return config_hash
      end
    else
      if (path.basename.to_s.downcase.start_with?('test'))
        Rails.logger.debug "Not loading #{path.to_s} as it is a configuration file for test"
        return config_hash
      end
    end

    # Check if file is yml or erb
    if path.extname != '.yml' && path.extname != '.erb'
      Rails.logger.debug "Not loading #{path.to_s} as it is not a .yml or a .erb file"
      return config_hash
    end

    # If file is yml, add it to config
    if path.extname == '.yml'
      Rails.logger.info "Loading contents of #{path.to_s} to config"
      config_hash = config_hash.deep_merge(YAML.load_file(path.to_s))
      return config_hash
    end

    # If file is a yaml.erb file, add it to config including erb interpretation
    if path.extname == '.erb'
      Rails.logger.info "Loading contents of #{path.to_s} to config"
      config_hash = config_hash.deep_merge(YAML.load(ERB.new(File.read(path.to_s)).result))
      return config_hash
    end

  end

  # Generates a combined config/config_full.yml file containing all config data
  def self.generate_file(base_file_path:)
    app_config = load_config_structure(base_file_path: base_file_path)
    config_file = File.open("#{Rails.root}/config/config_full.yml", "w:utf-8") do |file|
      file.write(app_config.to_yaml)
    end
  end

end

# If in test environment, generate file. Otherwise it should already exist.
if Rails.env == 'test'
  ConfigLoader.generate_file(base_file_path: "#{Rails.root}/config/app-config.yml")
end
main_config = YAML.load_file("#{Rails.root}/config/config_full.yml")

APP_CONFIG = main_config

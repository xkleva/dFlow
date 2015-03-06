main_config = YAML.load_file("#{Rails.root}/config/config.yml")
secret_config = YAML.load_file("#{Rails.root}/config/config_secret.yml")
APP_CONFIG = main_config.merge(secret_config)
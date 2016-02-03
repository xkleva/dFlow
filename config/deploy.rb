# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'dFlow'
set :repo_url, 'https://github.com/ub-digit/dFlow.git'

# Copied into /{app}/shared/config from respective sample file
set :linked_files, %w{config/database.yml config/config_full.yml config/passwd}
set :rvm_ruby_version, '2.1.5'      # Defaults to: 'default'

# Returns config for current stage assigned in config/deploy.yml
def deploy_config
  @config ||= YAML.load_file("config/deploy.yml")
  stage = fetch(:stage)
  return @config[stage.to_s]
end

server deploy_config['host'], user: deploy_config['user'], roles: deploy_config['roles']

set :deploy_to, deploy_config['path']



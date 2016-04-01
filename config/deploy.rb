# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'dFlow'
set :repo_url, 'https://github.com/ub-digit/dFlow.git'

set :rvm_ruby_version, '2.1.5'      # Defaults to: 'default'

# Returns config for current stage assigned in config/deploy.yml
def deploy_config
  @config ||= YAML.load_file("config/deploy.yml")
  stage = fetch(:stage)
  return @config[stage.to_s]
end

# Copied into /{app}/shared/config from respective sample file
set :linked_files, deploy_config['linked_files']

server deploy_config['host'], user: deploy_config['user'], roles: deploy_config['roles'], port: deploy_config['port']

set :deploy_to, deploy_config['path']



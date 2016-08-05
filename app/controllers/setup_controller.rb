class SetupController < ApplicationController

  class ::Hash
    def deep_merge(second)
      merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      self.merge(second, &merger)
    end
  end

  http_basic_authenticate_with name: APP_CONFIG['username'], password: APP_CONFIG['password']

  def index
    @error_fields = {}
    if APP_CONFIG['_is_setup']
      @is_setup = true
    end
    render 'setup'
  end

  def configindex
    @error_fields = {}
    if APP_CONFIG['_is_setup']
      @is_setup = true
    end
    render 'setup'
  end

  def update
    app_config = APP_CONFIG || {}
    json_fields = params[:json_fields] || {}
    @error_fields = {}
    json_fields.each do |key, value|
      begin
        params[:config][key] = JSON.parse(params[:config][key])
      rescue JSON::ParserError => e
        @error_fields[key] = params[:config][key]
      end
    end
    if @error_fields.size > 0
      render 'setup'
      return
    end
    app_config = app_config.deep_merge(params[:config])
    app_config['_is_setup'] = true
    config_file = File.open(APP_CONFIG_FILE_LOCATION, "w:utf-8") do |file|
      file.write(app_config.to_yaml)
    end

    FileUtils.mkdir_p(Rails.root.to_s + "/tmp")
    FileUtils.touch([Rails.root.to_s + "/tmp/restart.txt"])

    redirect_to action: 'index'
  end
end

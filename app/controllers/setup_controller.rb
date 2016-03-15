class SetupController < ApplicationController

  def index
    @error_fields = {}
    if APP_CONFIG['is_setup']
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
        @error_fields[key] = 1
      end
    end
    if @error_fields.size > 0
      render 'setup'
      return
    end
    app_config = app_config.merge(params[:config])
    app_config['is_setup'] = true
    config_file = File.open(APP_CONFIG_FILE_LOCATION, "w:utf-8") do |file|
      file.write(app_config.to_yaml)
    end

    redirect_to action: 'index'
  end
end

class Api::StatisticsController < Api::ApiController
  before_filter -> { validate_rights 'manage_statistics' }
  resource_description do
    short 'Provider of the Excel file containing job data for statistics'
  end

  api :POST, '/statistics', 'Starts the creation of a job data for statistics Excel file'
  example '{"script":{"process_name":"EXPORT_JOB_DATA_FOR_STATISTICS","params":{"start_date":"2018-01-01","end_date":"2018-01-31","file_name":"dFlow-statistikdata_2018-01-01_till_2018-01-31_(uttaget_2018-04-14_13.36.50).xls","sheet_name":"2018-01-01 till 2018-01-31"}}}'
  def create
    if !params[:statistics]
      error_msg(ErrorCodes::REQUEST_ERROR, "Unable to run file creation process")
    else
      process_name  = params[:statistics][:process_name] # i.e. = "EXPORT_JOB_DATA_FOR_STATISTICS"
      script_params = params[:statistics][:params]
      errors = ScriptManager.param_error_check(process_name: process_name,
                                               params:       script_params)
      if errors.present?
        error_msg(ErrorCodes::VALIDATION_ERROR, "Could not start process #{process_name}", errors)
        render_json
        return
      end
      id = ScriptManager.run(process_name: process_name,
                             params:       script_params)
      if !id
        error_msg(ErrorCodes::REQUEST_ERROR, "Unable to run process #{process_name}")
      else
        @response[:statistics] = {
          id: id
        }
      end
    end
    render_json
  end

  api :GET, '/statistics/:id', 'Polls the current status of the file creation process'
  def get_build_status
    id = params[:id]
    @response[:statistics] = {
      id:           id,
      build_status: ScriptManager.redis.get("dFlow:scripts:#{id}:build_status")
    }
    render_json
  end

  api :GET, '/statistics/download/:id', 'Sends the job data for statistics Excel file to the user'
  def download
    @redis             = ScriptManager.redis
    id                 = params[:id]
    file_name          = @redis.get("dFlow:scripts:#{id}:filename")
    xls_data_as_string = @redis.get("dFlow:scripts:#{id}:xls_data_as_string")
    send_xls_data(file_name, xls_data_as_string)
  end

 private

  def send_xls_data(file_name, xls_data_as_string)
    begin
      send_data xls_data_as_string.force_encoding('binary'), 
                filename:     file_name, 
                type:        "application/excel", 
                disposition: "attachment"
    rescue Exception => e
      pp e.message
    end
  end

end



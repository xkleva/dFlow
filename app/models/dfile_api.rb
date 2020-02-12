require 'httparty'
require 'redis'
require 'open-uri'

class DfileApi

  def self.api_key
    APP_CONFIG['dfile_api_key']
  end

  def self.host
    APP_CONFIG['dfile_base_url']
  end

  def self.logger=(logger)
    @@logger ||= nil
    @@logger = logger
  end

  def self.logger
    @@logger ||= Logger.new("#{Rails.root}/log/dfile_api.log")
  end

  # Returns true of connection is successful
  def self.check_connection
    return
    check = HTTParty.get("#{host}/api/check_connection?api_key=#{api_key}")
    if check.nil? || check["status"]["code"] < 0
      logger.fatal "Script was unable to establish connection with dFile at #{host}"
    end
  end

  def self.download_file(source_file:)
    url = URI.parse("#{host}/download_file")
    params = {
      source_file: source_file,
      api_key: api_key
    }
    url.query = params.to_param

    return open(url.to_s) 
  end

  def self.thumbnail(source_dir:, source:, image:, filetype: nil, size: nil)
    response = HTTParty.get("#{host}/thumbnail", query: {
      source_dir: source_dir,
      filetype: filetype,
      source: source,
      image: image,
      size: size,
      api_key: api_key
    })

    if response.success?
      return JSON.parse(response.body)
    else
      raise StandardError, "Couldn't list files in #{source_dir}, with message #{response['error']}"
    end
  end

  # Returns array of {:name, :size}
  def self.list_files(source_dir:, extension: nil, show_catalogues: true)
    response = HTTParty.get("#{host}/list_files", query: {
      source_dir: source_dir,
      ext: extension,
      show_catalogues: show_catalogues,
      api_key: api_key
    })

    if response.success?
      return JSON.parse(response.body)
    else
      raise StandardError, "Couldn't list files in #{source_dir}, with message #{response['error']}"
    end
  end

  def self.file_exist?(source_file:)
    response = HTTParty.get("#{host}/download_file.json", query: {
      source_file: source_file,
      api_key: api_key
    })

    if response.success?
      return JSON.parse(response.body)
    else
      return false
    end
  end

  def self.move_file(from_source:, from_file:, to_source:, to_file:)
    response = HTTParty.get("#{host}/move_file", query: {
      source_file: "#{from_source}:/#{from_file}",
      dest_file: "#{to_source}:/#{to_file}",
      api_key: api_key
    })

    if response.success?
      return response.body
    else
      raise StandardError, "Couldn't move file #{from_source} #{from_file} to #{to_source} #{to_file}, with message: #{response['error']}"
    end
  end

  def self.move_folder(from_source:, from_dir:, to_source:, to_dir:)
    response = HTTParty.get("#{host}/move_folder", query: {
      source_dir: "#{from_source}:#{from_dir}",
      dest_dir: "#{to_source}:#{to_dir}",
      api_key: api_key
    })

    if response.success?
      return true
    else 
      raise StandardError, "Couldn't move folder #{from_source} #{from_dir} to #{to_source} #{to_dir}, with response #{response['error']}"
    end

  end

  def self.copy_folder_ind(source_dir:, dest_dir:, flow_step: nil, format_params: nil, filetype: nil)
    logger.debug "#########  Starting copy_folder request from #{source_dir} to #{dest_dir} #########"
    response = HTTParty.get("#{host}/copy_folder_ind", query: {
      source_dir: source_dir,
      dest_dir: dest_dir,
      format_params: format_params,
      filetype: filetype,
      api_key: api_key
    })


    logger.debug "Response from dFile: #{response.inspect}"
    if !response.success?
      raise StandardError, "Could not start a process through dFile: #{response['error']}"
    end

    process_id = response['id']

    logger.debug "Process id: #{process_id}"
    if !process_id || process_id == ''
      raise StandardError, "Did not get a valid Process ID: #{process_id}"
    end

    process_result = get_process_result(process_id: process_id, flow_step: flow_step)
    logger.debug "Process result: #{process_result}"

    return process_result

  end

  # Moves a folder to trash location
  def self.move_to_trash(source_dir:)
    response = HTTParty.get("#{host}/move_to_trash", query: {
      source_dir: source_dir,
      api_key: api_key
    })

    if response.success?
      return true
    else
      return false
    end
  end

  def self.create_format(source_dir:, dest_dir:, to_filetype:, format_params:, flow_step: nil)
    logger.debug "#########  Starting create_format request from #{source_dir} to #{dest_dir} with #{format_params} #########"
    response = HTTParty.get("#{host}/convert_images", query: {
      source_dir: source_dir,
      dest_dir: dest_dir,
      to_filetype: to_filetype, 
      format_params: format_params,
      api_key: api_key
    })


    logger.debug "Response from dFile: #{response.inspect}"
    if !response.success?
      raise StandardError, "Could not start a process through dFile: #{response['error']}"
    end

    process_id = response['id']

    logger.debug "Process id: #{process_id}"
    if !process_id || process_id == ''
      raise StandardError, "Did not get a valid Process ID: #{process_id}"
    end

    process_result = get_process_result(process_id: process_id, flow_step: flow_step)
    logger.debug "Process result: #{process_result}"

    return process_result

  end

  def self.move_folder_ind(source_dir:, dest_dir:, flow_step: nil, format_params: nil, filetype: nil)
    logger.debug "#########  Starting move_folder request from #{source_dir} to #{dest_dir} #########"
    response = HTTParty.get("#{host}/move_folder_ind", query: {
      source_dir: source_dir,
      dest_dir: dest_dir,
      format_params: format_params,
      filetype: filetype,
      api_key: api_key
    })


    logger.debug "Response from dFile: #{response.inspect}"
    if !response.success?
      raise StandardError, "Could not start a process through dFile: #{response['error']}"
    end

    process_id = response['id']

    logger.debug "Process id: #{process_id}"
    if !process_id || process_id == ''
      raise StandardError, "Did not get a valid Process ID: #{process_id}"
    end

    process_result = get_process_result(process_id: process_id, flow_step: flow_step)
    logger.debug "Process result: #{process_result}"

    return process_result

  end

  # TODO: Needs error handling
  # returns {:checksum, :msg}
  def self.checksum(source_file_path:)
    response = HTTParty.get("#{host}/checksum", query: {
      source_file: source_file_path,
      api_key: api_key
    })

    if !response.success?
      raise StandardError, "Could not start a process through dFile: #{response['error']}"
    end

    process_id = response['id']

    if !process_id || process_id == ''
      raise StandardError, "Did not get a valid Process ID: #{process_id}"
    end

    process_result = get_process_result(process_id: process_id)

    return process_result
  end

  # Creates a file with given content
  def self.create_file(dest_file:, content:, permission: nil)
    body = { dest_file: dest_file,
             content: content,
               api_key: api_key
    }
    if !permission.nil?
      body['force_permission'] = permission
    end

    response = HTTParty.post("#{host}/create_file", body: body)

    if response.success?
      return true
    else
      raise StandardError, "DFileApi: Could not create file: #{dest_file}"
    end
  end

  # Copies a file
  def self.copy_file(source_file:, dest_file:)
    response = HTTParty.get("#{host}/copy_file", query: {
      source_file: source_file,
      dest_file: dest_file,
      api_key: api_key
    })

    if response.success?
      return true
    else
      raise StandardError, "Couldn't copy file: #{source_file} to #{dest_file}, with message: #{response['error']}"
    end
  end

  def self.rename_files(source_dir:, format:)
    response = HTTParty.get("#{host}/rename_files", query: {
      source_dir: source_dir,
      string_format: format,
      api_key: api_key
    })

    if response.success?
      return true
    else
      raise StandardError, "Couldn't rename files in: #{source_dir} #{response['error']}"
    end
  end

  def self.delete_job_files(job_path:)
    
    response = HTTParty.get("#{host}/delete_files", query: {
      source_dir: job_path,
      api_key: api_key
    })

    if response.success?
      return true
    else
      raise StandardError, "Couldn't delete job files files in: #{job_path} #{response['error']}"
    end
  end

  def self.combine_pdf_files(source_dir:, dest_file:)
    response = HTTParty.get("#{host}/combine_pdf_files", query: {
      source_dir: source_dir,
      dest_file: dest_file,
      api_key: api_key
    })

    logger.debug "Response from dFile: #{response.inspect}"
    if !response.success?
      raise StandardError, "Could not start a process through dFile: #{response['error']}"
    end

    process_id = response['id']

    logger.debug "Process id: #{process_id}"
    if !process_id || process_id == ''
      raise StandardError, "Did not get a valid Process ID: #{process_id}"
    end

    process_result = get_process_result(process_id: process_id)
    logger.debug "Process result: #{process_result}"

    return process_result
  end

  def self.get_file_metadata_info(source_dir:)
    response = HTTParty.get("#{host}/get_file_metadata_info", query: {
      source_dir: source_dir,
      api_key: api_key
    })

    if response.success?
      return JSON.parse(response.body)
    else
      raise StandardError, "Couldn't get file in #{source_dir}, with message #{response['msg']}"
    end
  end

  private
  # Returns result from redis db
  def self.get_process_result(process_id:, flow_step: nil)

    # Load Redis config
    redis = Redis.new(db: APP_CONFIG['redis_db']['db'], host: APP_CONFIG['redis_db']['host'])

    while !redis.get("dFile:processes:#{process_id}:state:done") do
      if flow_step
        flow_step.update_attribute('status', redis.get("dFile:processes:#{process_id}:progress"))
      end
      sleep 0.1
    end
    if flow_step
      flow_step.update_attribute('status', redis.get("dFile:processes:#{process_id}:progress"))
    end

    value = redis.get("dFile:processes:#{process_id}:value")

    logger.info "Value from Redis for #{process_id}: #{value}"
    if !value || value == "error"
      if flow_step
        flow_step.update_attribute('status', redis.get("dFile:processes#{process_id}:error"))
      end
      raise StandardError, redis.get("dFile:processes:#{process_id}:error")
    end

    return value
  end
end

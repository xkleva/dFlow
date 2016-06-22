class WaitForFiles

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    folder_path = params['folder_path']
    filetype = params['filetype']
    count = params['count'].to_i

    file_list = get_files(folder_path: folder_path, filetype: filetype)

    logger.info "File count for #{folder_path} *.#{filetype} : #{file_list.count}/#{count}"
    job.flow_step.update_attribute('status', "File count: #{file_list.count}/#{count}")

    if file_list.count != count
      return false
    else
      return true
    end

  end

  def self.get_files(folder_path:, filetype:)
    source,directory = folder_path.split(/:/, 2)

    return DfileApi.list_files(source, directory, filetype)
  end
end

class WaitForFiles

  def self.run(job:, logger: QueueManager.logger, folder_path:, filetype:, count:)
    file_list = get_files(folder_path: folder_path, filetype: filetype)

    logger.info "File count for #{folder_path} *.#{filetype} : #{file_list.count}/#{count}"
    job.flow_step.update_attribute('status', "File count: #{file_list.count}/#{count}")

    if file_list.count != count.to_i
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

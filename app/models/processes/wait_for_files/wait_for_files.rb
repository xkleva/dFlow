class WaitForFiles

  def self.run(job:, logger: QueueManager.logger, folder_path:, filetype:, count:)
    file_list = get_files(folder_path: folder_path, filetype: filetype)

    logger.info "File count for #{folder_path} *.#{filetype} : #{file_list.count}/#{count}"
    job.flow_step.update_attribute('status', "File count: #{file_list.count}/#{count}")

    if file_list.count != count.to_i
      if file_list.count > count.to_i
        file_suffix = count.to_i == 1 ? "file" : "files"
        raise StandardError, "There are too many files. Expected #{count.to_i} #{file_suffix}, but found #{file_list.count} instead"
      end
      return false
    else
      return true
    end

  end

  def self.get_files(folder_path:, filetype:)

    return DfileApi.list_files(source_dir: folder_path, extension: filetype)
  end
end

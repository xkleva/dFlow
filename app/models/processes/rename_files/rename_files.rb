class RenameFiles

  def self.run(job:, logger: QueueManager.logger, folder_path:, format_params:)

    if DfileApi.rename_files(source_dir: folder_path, format: format_params)
      return true
    else
      return false
    end
  end

end

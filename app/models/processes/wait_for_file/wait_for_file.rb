class WaitForFile

  def self.run(job:, logger: QueueManager.logger, file_path:)

    result = DfileApi.file_exist?(source_file: file_path)

    if result
      logger.info "File #{file_path} found!"
      return true
    else
      logger.info "File #{file_path} does not exist"
      return false
    end

  end
end

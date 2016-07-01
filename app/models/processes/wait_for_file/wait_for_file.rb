class WaitForFile

  def self.run(job:, logger: QueueManager.logger, file_path:)

    source,file = file_path.split(/:/, 2)
    result = FileAdapter.file_exists?(source, file)

    if result
      logger.info "File #{file_path} found!"
      return true
    else
      logger.info "File #{file_path} does not exist"
      return false
    end

  end
end

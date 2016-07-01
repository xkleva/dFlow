class CopyFile

  def self.run(job:, logger: QueueManager.logger, source_file_path:, destination_file_path:)

    if DfileApi.copy_file(source_file: source_file_path, dest_file: destination_file_path)
      return true
    else
      return false
    end

  end
end

class CreateFormat

  def self.run(job:, logger: QueueManager.logger, source_folder_path:, destination_folder_path:, to_filetype:, format_params:)

    if DfileApi.create_format(source_dir: source_folder_path, dest_dir: destination_folder_path, to_filetype: to_filetype, format_params: format_params, flow_step: job.flow_step)
      return true
    else
      return false
    end
  end
end

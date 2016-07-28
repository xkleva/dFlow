class CopyFolder

  def self.run(job:, logger: QueueManager.logger, source_folder_path:, destination_folder_path:, format_params: '', filetype: nil)

    if DfileApi.copy_folder_ind(source_dir: source_folder_path, dest_dir: destination_folder_path, flow_step: job.flow_step, format_params: format_params, filetype: filetype)
      return true
    else
      return false
    end
  end
end

class MoveFolder

  def self.run(job:, logger: QueueManager.logger, source_folder_path:, destination_folder_path:, format_params: nil, filetype: nil)
    if DfileApi.move_folder_ind(source_dir: source_folder_path, dest_dir: destination_folder_path, flow_step: job.flow_step, format_params: format_params, filetype: nil)
      return true
    else
      return false
    end
  end
end

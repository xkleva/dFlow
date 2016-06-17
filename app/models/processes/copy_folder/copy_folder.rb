class CopyFolder

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    source_folder_path = params['source_folder_path']
    destination_folder_path = params['destination_folder_path']

    if DfileApi.copy_folder_ind(source_dir: source_folder_path, dest_dir: destination_folder_path, flow_step: job.flow_step)
      return true
    else
      return false
    end
  end
end

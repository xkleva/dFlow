class CreateFormat

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    source_folder_path = params['source_folder_path']
    destination_folder_path = params['destination_folder_path']
    to_filetype = params['to_filetype']
    format_params = params['format']

    if DfileApi.create_format(source_dir: source_folder_path, dest_dir: destination_folder_path, to_filetype: to_filetype, format_params: format_params, flow_step: job.flow_step)
      return true
    else
      return false
    end
  end
end

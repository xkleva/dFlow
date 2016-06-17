class CopyFile

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    source_file_path = params['source_file_path']
    destination_file_path = params['destination_file_path']

    if DfileApi.copy_file(source_file: source_file_path, dest_file: destination_file_path)
      return true
    else
      return false
    end
  end
end

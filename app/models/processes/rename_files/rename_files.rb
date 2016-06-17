class RenameFiles

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    folder_path = params['folder_path']
    format = params['format']

    if DfileApi.rename_files(source_dir: folder_path, format: format)
      return true
    else
      return false
    end
  end

end

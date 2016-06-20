class CombinePdfFiles

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    source_folder_path = params['source_folder_path']
    destination_file_path = params['destination_file_path']

    if DfileApi.combine_pdf_files(source_dir: source_folder_path, dest_file: destination_file_path)
      return true
    else
      return false
    end
  end
end

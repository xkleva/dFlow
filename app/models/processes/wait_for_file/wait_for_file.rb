class WaitForFile

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    file_path = params['file_path']

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

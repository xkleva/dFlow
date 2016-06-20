class DeleteJobFiles

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    job_parent_path = params['job_parent_path']

    job_id = job.id

    if job_id.nil? || job_id <= 0 || Job.find(job_id).nil? 
      return false
    end

    job_path = "#{job_parent_path}/#{job_id}"

    if DfileApi.delete_job_files(job_path: job_path)
      return true
    else
      return false
    end
  end
end

class ChangePackageLocation

  def self.run(job:, logger: QueueManager.logger, new_package_location:)
    if job.update_attribute('package_location', new_package_location)
      return true
    else
      return false
    end
  end
end

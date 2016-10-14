class CollectJobMetadata

  def self.run(job:, logger: QueueManager.logger, folder_path:, filetype:)
    file_list = get_files(folder_path: folder_path, filetype: filetype)

    logger.info "File count for #{folder_path} *.#{filetype} : #{file_list.count}"

    # Quarantine if count is 0
    if file_list.count == 0
      raise StandardError, "No images were found."
    end
    
    images = []

    file_list.each do |image|
      img_object = {
        num: File.basename(image['name'], ".*"),
        page_type: "Undefined",
        page_content: "Undefined"
      }

      images << img_object
    end

    if job.update_attribute('package_metadata', {images: images, image_count: images.size}.to_json)
      return true
    else
      raise StandardError, "Unable to update database."
    end

  end

  def self.get_files(folder_path:, filetype:)

    return DfileApi.list_files(source_dir: folder_path, extension: filetype)
  end

end

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

    res = get_file_metadata(folder_path: folder_path)
    if res.compact.blank?
      raise StandardError, "Unable to get scanner info"
    end

    if job.update_attributes({package_metadata: {images: images, image_count: images.size}.to_json, scanner_make: res["make"], scanner_model: res["model"], scanner_software: res["software"]})
      return true
    else
      raise StandardError, "Unable to update database."
    end
  end

  def self.get_files(folder_path:, filetype:)
    return DfileApi.list_files(source_dir: folder_path, extension: filetype)
  end

  def self.get_file_metadata(folder_path:)
    return DfileApi.get_file_metadata_info(source_dir: folder_path)
  end
end

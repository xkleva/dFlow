class CollectJobMetadata

  def self.run(job:, logger:)
    params = job.flow_step.parsed_params
    folder_path = params['folder_path']
    filetype = params['filetype']

    file_list = get_files(folder_path: folder_path, filetype: filetype)

    logger.info "File count for #{folder_path} *.#{filetype} : #{file_list.count}"

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
      return false
    end

  end

  def self.get_files(folder_path:, filetype:)
    source,directory = folder_path.split(/:/, 2)

    return DfileApi.list_files(source, directory, filetype)
  end

end

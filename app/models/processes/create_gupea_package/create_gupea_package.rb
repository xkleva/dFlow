class CreateGupeaPackage
  require 'nokogiri'

  def self.run(job:, logger: QueueManager.logger, gupea_collection:, pdf_file_path:, gupea_folder_path:)
    if self.create_folder(job: job, collection_id: gupea_collection, gupea_folder: gupea_folder_path, pdf_file_path: pdf_file_path) && self.import_package(job: job)
      return true
    else
      return false
    end
  end

  def self.ordinals(job:)
    ordinals_string = ""
    hash = job.metadata_hash
    if hash['ordinal_1_key'] && hash['ordinal_1_value']
      ordinals_string = hash['ordinal_1_key'] + ' ' + hash['ordinal_1_value']
    end

    if hash['ordinal_2_key'] && hash['ordinal_2_value']
      ordinals_string += ', ' + hash['ordinal_2_key'] + ' ' + hash['ordinal_2_value']
    end

    if hash['ordinal_3_key'] && hash['ordinal_3_value']
      ordinals_string += ', ' + hash['ordinal_3_key'] + ' ' + hash['ordinal_3_value']
    end

    ordinals_string
  end

  def self.chronologicals(job:)
    chronologicals_string = ""
    hash = job.metadata_hash

    if hash['chron_1_key'] && hash['chron_1_value']
      chronologicals_string = hash['chron_1_key'] + ' ' + hash['chron_1_value']
    end

    if hash['chron_2_key'] && hash['chron_2_value']
      chronologicals_string += ', ' + hash['chron_2_key'] + ' ' + hash['chron_2_value']
    end

    if hash['chron_3_key'] && hash['chron_3_value']
      chronologicals_string += ', ' + hash['chron_3_key'] + ' ' + hash['chron_3_value']
    end

    chronologicals_string
  end

  def self.chronologicals_year(job:)
    if job.metadata_hash.has_key?('chron_1_value')
      return job.metadata_hash['chron_1_value'].to_i
    else
      return 0
    end
  end

  def self.create_xml(job:)

    xml = Nokogiri::XML('<?xml version = "1.0" encoding = "UTF-8" standalone ="no"?>')
    #puts Nokogiri::XML::Builder.with(xml) { |x| x.awesome }.to_xml
    builder = Nokogiri::XML::Builder.with(xml) do |xml|
      xml.dublin_core(:schema => "dc") {
        xml.dcvalue(:element => "title", :qualifier => "none") {
          if job.is_periodical
            xml.text "#{job.title} (#{self.ordinals(job: job)})"
          else
            xml.text job.title
          end
        }
        xml.dcvalue(:element => "contributor", :qualifier => "author") {
          xml.text job.author
        }
        xml.dcvalue(:element => "date", :qualifier => "issued") {
          if job.is_periodical
            xml.text self.chronologicals_year(job: job)
          else
            if job.metadata_hash['year'].to_i > 0
              xml.text job.metadata_hash['year'].to_i
            elsif job.source == 'libris'
              metadata = Libris.data_from_record(job.xml)[:metadata]
              if metadata.present? && metadata[:year].present?
                xml.text metadata[:year]
              else
                xml.text 0
              end
            else
              xml.text 0
            end
          end
        }
        xml.dcvalue(:element => "language", :qualifier => "iso") {
          xml.text job.metadata_hash['language'] || "swe"
        }
        xml.dcvalue(:element => "type", :qualifier => "marc") {
          xml.text job.metadata_hash['type_of_record']
        }
        xml.dcvalue(:element => "identifier", :qualifier => "librisid") {
          xml.text job.catalog_id
        }
        if job.is_periodical
          xml.dcvalue(:element => "identifier", :qualifier => "citation") {
            xml.text "#{self.ordinals(job: job)} - #{self.chronologicals(job: job)}"
          }
        end
      }
    end
    builder.to_xml
  end

  # Creates package folder for delivery
  def self.create_folder(job:, collection_id:, gupea_folder:, pdf_file_path:)
    # Create collection file
    DfileApi.create_file(dest_file: "#{gupea_folder}/collection", content: collection_id, permission: "0777")

    # Copy PDF from package
    DfileApi.copy_file(source_file: pdf_file_path, dest_file: "#{gupea_folder}/files/#{job.package_name}.pdf")

    # Create contents file
    DfileApi.create_file(dest_file: "#{gupea_folder}/files/contents", content: "#{job.package_name}.pdf")

    # Create DC file
    DfileApi.create_file(dest_file: "#{gupea_folder}/files/dublin_core.xml", content: create_xml(job: job))
  end

  # Sends signal to GUPEA server to import package
  def self.import_package(job:)
    response = HTTParty.get("http://gupea-server.ub.gu.se:81/dflow_import/#{job.id}")

    if !response || response["error"] || !response["url"]
      raise StandardError, "Error from service: #{response['error']} #{response['extra_info']}"
    else
      publicationlog = PublicationLog.new(job: job, publication_type: 'GUPEA', comment: response['url'])
      if !publicationlog.save
        raise StandardError, "Couldn't save publicationlog due to errors: #{publicationlog.errors}"
      end
    end

  end
end

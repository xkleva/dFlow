# coding: utf-8
#require_relative 'sources/dublin_core'
#require_relative 'sources/libris'
#require_relative 'sources/manuscript'
require 'yaml'

class CreateMetsFile

  def self.run(job:, logger: QueueManager.logger, 
               job_folder_path:, 
               mets_file_path:, 
               formats_required:, 
               files_required:,
               creator_name:, 
               creator_sigel:, 
               archivist_name: nil, 
               archivist_sigel: nil, 
               copyright_true_text: 'copyrighted', 
               copyright_false_text: 'pd', 
               require_physical: false, 
               validate_group_names: false,
               checksum: false
              )

    # Create arrays for formats and files
    formats_required = formats_required.split(",").compact.collect(&:strip)
    files_required = files_required.split(",")
    
    # Set archivist values to creator values if not given
    archivist_name = creator_name if archivist_name.nil?
    archivist_sigel = creator_sigel if archivist_sigel.nil?

    copyright_text = copyright_true_text if job.copyright
    copyright_text = copyright_false_text if !job.copyright

    # Normalise checksum to boolean
    if checksum == true || (checksum.kind_of?(String) && ['true', 't', 'yes', 'y'].include?(checksum.downcase))
      checksum = true
    else
      checksum = false
    end
    
    # Raise error if there is no page count info, needed to be able to validate package contents
    if job.page_count < 1
      raise StandardError, "Page count is needs to be a positive number, is: #{job.page_count}"
    end
 
    mets = MetsObject.new(job: job, logger: logger, job_folder_path: job_folder_path, mets_file_path: mets_file_path, copyright_text: copyright_text, creator_name: creator_name, creator_sigel: creator_sigel, archivist_name: archivist_name, archivist_sigel: archivist_sigel, formats_required: formats_required, files_required: files_required, checksum: checksum)
    mets.create_mets_xml_file
   
  end

  # Describing one file, used for handling locations, checksums, renaming
  class MetsFileObject
    attr_accessor :number, :checksum, :name, :extension, :mimetype

    MIMETYPES = {
      "jpg" => "image/jpeg",
      "tif" => "image/tiff",
      "xml" => "text/xml",
      "pdf" => "text/pdf",
      "txt" => "text/plain"
    }
    def initialize(job_id:, path:, filename:, size:, perform_checksum:)
      @job_id = job_id
      @path = path
      @name = filename
      @size = size
      @perform_checksum = perform_checksum
      @full_path = @path + "/" + @name
      @extension = filename.gsub(/^.*\.([^\.]+)$/,'\1')
      @number = filename.gsub(/^(\d+)\.[^\.]+$/,'\1')
      @mimetype = MIMETYPES[@extension]
      raise StandardError, "Extension is not configured as mimetype: #{@extension}" if !@mimetype
      if(@perform_checksum)
        @checksum = DfileApi.checksum(source_file_path: @full_path)
      end
    end

  end

  # Describing a file group containing multiple or single file(s)
  # Keeps track of file type (extension), directory name within job,
  # and whether or not there should be multiple or single file entries
  class MetsFileGroup
    attr_accessor :files, :name, :mimetype
    def initialize(job:, name:, extension:, single: false, folder_path:, file_path: nil, perform_checksum: false)
      @job = job
      @job_id = job.id
      @name = name
      @single = single
      @files = []
      @folder_path = folder_path
      @file_path = file_path
      @extension = extension
      @perform_checksum = perform_checksum
      add_files
      @extension = @files.first.extension
      @mimetype = @files.first.mimetype
    end

    # Keep track of all relevant files in the directory
    def add_files
      DfileApi.list_files(source_dir: @folder_path, extension: @extension).each do |file|
        @files << MetsFileObject.new(job_id: @job_id, path: @folder_path, filename: file['name'], size: file['size'], perform_checksum: @perform_checksum)
      end
      count = @job.page_count
      if @single
        count = 1
      end
      # TODO: Raise exception if files do not correspond to jobs file count if single flag is false
      if @files.count != count
        raise StandardError, "Wrong number of files for #{@name} in #{@folder_path}, wanted: #{count}, found: #{@files.count}"
      end
    end

    # Only a single file should be kept in this group
    def single?
      @single
    end
  end

  # Setup all necessary parts for creating METS XML
  class MetsObject

    def initialize(job:, 
                   logger: Logger.new("#{Rails.root}/log/create_mets_package.log"), 
                   job_folder_path:, 
                   mets_file_path:, 
                   copyright_text:, 
                   creator_name:, 
                   creator_sigel:, 
                   archivist_name:, 
                   archivist_sigel:,
                   formats_required:,
                   files_required:,
                   checksum:
                  )
      @job = job
      @logger = logger
      @copyright_text = copyright_text
      @creator_name = creator_name
      @creator_sigel = creator_sigel
      @archivist_name = archivist_name
      @archivist_sigel = archivist_sigel
      @job_folder_path = job_folder_path
      @mets_file_path = mets_file_path
      @formats_required = formats_required
      @files_required = files_required
      @perform_checksum = checksum

      case @job.source
      when 'libris'
        @source = CreateMetsFile::Libris.new(@job, mets_data)
      when 'dc'
        @source = CreateMetsFile::DublinCore.new(@job, mets_data)
      when 'document'
        @source = CreateMetsFile::Manuscript.new(@job, mets_data, 'document')
      when 'letter'
        @source = CreateMetsFile::Manuscript.new(@job, mets_data, 'letter')
      end

      @file_groups = []
      @formats_required.each do |format|
        name, extension = format.split('-')
        if !name.present? || !extension.present?
          raise StandardError, "Wrong format: #{format} , should be formatted according to <folder>-<extenstion> e.g. master-tif"
        end
        @file_groups << MetsFileGroup.new(job: @job, name: name, extension: extension, folder_path: @job_folder_path + "/" + name, perform_checksum: @perform_checksum)
      end
      @files_required.each do |file|
        path = Pathname.new(file)
        name = path.dirname.to_s.split('/').last
        extension = file.split('.').last
        if !name.present?
          raise StandardError, "Files must be placed in a sub-folder and not in the root of the package."
        end
        if !extension.present?
          raise StandardError, "Wrong file: #{file} , should be formatted according to <folder>/<filename>.<extension>"
        end
        @file_groups << MetsFileGroup.new(job: @job, name: name, extension: extension, folder_path: @job_folder_path + '/' + name, single: true, file_path: file, perform_checksum: @perform_checksum)
      end

    end

    # Creates the mets xml file in package folder
    def create_mets_xml_file
      content = mets_xml
      if !xml_valid?(content)
        raise StandardError, "Invalid XML"
      end
      DfileApi.create_file(dest_file: @mets_file_path, content: mets_xml)
    end

    def xml_valid?(xml)
      test = Nokogiri::XML(xml)
      test.errors.empty?
    end

    # Collect global data used by METS production in various places
    def mets_data
      {
        id: @job.package_name,
        created_at: DateTime.parse(@job.created_at.to_s).strftime("%FT%T"),
        updated_at: DateTime.parse(@job.updated_at.to_s).strftime("%FT%T"),
        creator_sigel: @creator_sigel,
        creator_name: @creator_name,
        archivist_sigel: @archivist_sigel,
        archivist_name: @archivist_name,
        copyright_status: @copyright_text,
        publication_status: 'unpublished'
      }
    end

    # Build actual METS XML from all the pieces
    def mets_xml
      xml = head
      xml += extra_dmdsecs
      xml += bibliographic
      xml += administrative
      xml += filegroup_sections
      xml += structure_section_physical
      xml += structure_section_logical
      Nokogiri::XML(root(xml), &:noblanks).to_xml(encoding:'utf-8', indent: 2)
    end

    # Root element wrapper for METS XML
    ##
    # så sva det vara:
    #<mets:mets
    #xmlns:mets="http://www.loc.gov/METS/"
    #xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #xmlns:rights="http://www.loc.gov/rights/"
    #xmlns:xlink="http://www.w3.org/1999/xlink"
    #xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd">
    #
    def root(xml)
      %Q(<mets:mets xmlns:mets="http://www.loc.gov/METS/"
       xmlns:xlink="http://www.w3.org/1999/xlink"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd">#{xml}</mets:mets>)
    end

    # METS XML header information
    #  Creator and archivist
    def head
      %Q{<mets:metsHdr ID="#{mets_data[:id]}"
      CREATEDATE="#{mets_data[:created_at]}" LASTMODDATE="#{mets_data[:updated_at]}"
      RECORDSTATUS="complete">
      <mets:agent ROLE="CREATOR" TYPE="ORGANIZATION" ID="creator_#{mets_data[:creator_sigel]}">
      <mets:name>#{mets_data[:creator_name]}</mets:name>
      </mets:agent>
      <mets:agent ROLE="ARCHIVIST" TYPE="ORGANIZATION" ID="archivist_#{mets_data[:archivist_sigel]}">
      <mets:name>#{mets_data[:archivist_name]}</mets:name>
      </mets:agent>
      </mets:metsHdr>}
    end

    # METS XML administrative information
    #  Copyright/publication status
    def administrative
      %Q(<mets:amdSec ID="amdSec1" >
        <mets:rightsMD ID="rightsDM1">
        <mets:mdWrap MDTYPE="OTHER">
        <mets:xmlData>
        <copyright copyright.status="#{mets_data[:copyright_status]}" publication.status="#{mets_data[:publication_status]}" xsi:noNamespaceSchemaLocation="http://www.cdlib.org/groups/rmg/docs/copyrightMD.xsd"/>
        </mets:xmlData>
        </mets:mdWrap>
        </mets:rightsMD>
        </mets:amdSec>)
    end

    # METS XML bibliographic information
    #  Translated (if necessary) output of source XML data
    #
    # Content handled by @source
    def bibliographic
      %Q(<mets:dmdSec ID="dmdSec1" CREATED="#{mets_data[:created_at]}">
        <mets:mdWrap MDTYPE="#{@source.xml_type}">
        <mets:xmlData>
      #{@source.xml_data}
        </mets:xmlData>
        </mets:mdWrap>
        </mets:dmdSec>)
    end

    # METS XML Special dmdSec:s for image data for manuscript sources
    #
    # Content handled by @source
    def extra_dmdsecs
      @source.extra_dmdsecs
    end

    # METS XML file section
    #  Single file entry with id, mimetype, path/name and checksum
    def file_section(file_group, file)
      if(@perform_checksum)
        checksum_string = " CHECKSUMTYPE=\"SHA-512\" CHECKSUM=\"#{file.checksum}\" "
      end
      %Q(<mets:file ID="#{file_group.name}#{file.number}"
        MIMETYPE="#{file_group.mimetype}"
        #{checksum_string}>
        <mets:FLocat LOCTYPE="URL" xlink:href="#{file_group.name}/#{file.name}" />
        </mets:file>)
    end

    # METS XML file group section
    #  Single file group entry collecting files
    def filegroup_section(file_group)
      file_data = file_group.files.map do |file|
        file_section(file_group, file)
      end
      %Q(<mets:fileGrp USE="#{file_group.name}">#{file_data.join("")}</mets:fileGrp>)
    end

    # METS XML file group sections
    #  Wrapper for all file group sections
    def filegroup_sections
      file_group_data = @file_groups.map do |file_group|
        filegroup_section(file_group)
      end
      %Q(<mets:fileSec ID="fileSec1">#{file_group_data.join("")}</mets:fileSec>)
    end

    # METS XML structure section for logical structure
    #  Single entry for one image, and its logical content information
    #  Titlepage/Image/Text
    def structure_image_logical(image)
      image_num = image['num'].to_i
      image_group = image['group_name']
      dmdid = @source.dmdid_attribute(image_group)

      image_filegroup_data = @file_groups.map do |file_group|
        next '' if file_group.single?
        "<mets:fptr FILEID=\"#{file_group.name}#{sprintf("%04d", image_num)}\"/>"
      end

      %Q(<mets:div TYPE="#{image['page_content']}"
       ID="logical_divpage#{image_num}"
       ORDER="#{image_num}"#{dmdid}>
      #{image_filegroup_data.join("")}
       </mets:div>)
    end

    # METS XML structure section for physical structure
    #  Single entry for one image, and its physical type information
    #  Right/Left/"Cover"/...
    def structure_image_physical(image)
      image_num = image['num'].to_i
      image_filegroup_data = @file_groups.map do |file_group|
        next '' if file_group.single?
        "<mets:fptr FILEID=\"#{file_group.name}#{sprintf("%04d", image_num)}\"/>"
      end

      %Q(<mets:div TYPE="#{image['page_type']}"
       ID="physical_divpage#{image_num}"
       ORDER="#{image_num}">
      #{image_filegroup_data.join("")}
       </mets:div>)
    end

    # METS XML structure for logical entries
    #  Wrapper for all logical structure entries
    def structure_section_logical
      structure_data = @job.package_metadata_hash['images'].map do |image|
        structure_image_logical(image)
      end

      %Q(<mets:structMap TYPE="Logical">
       <mets:div TYPE="#{@source.type_of_record}">
      #{structure_data.join('')}
       </mets:div>
       </mets:structMap>)
    end

    # METS XML structure for physical entries
    #  Wrapper for all physical structure entries
    def structure_section_physical
      #pp @job['package_metadata']
      structure_data = @job.package_metadata_hash['images'].map do |image|
        structure_image_physical(image)
      end

      %Q(<mets:structMap TYPE="Physical">
       <mets:div TYPE="#{@source.type_of_record}">
      #{structure_data.join('')}
       </mets:div>
       </mets:structMap>)
    end
  end
end

#
# Class for defining an import source for Jobs
# The data returned will be used for job creation
# Data is supporded in the following format:
# {title: "String", author: "String", metadata: {}, xml: "String", source_id: int, catalog_id: int}
#

require 'open-uri'

class Libris < Source
  # There is no schema for libris right now
  XML_SCHEMA = nil
  LIBRIS_XSEARCH_MARC = "http://libris.kb.se/xsearch?format=marcxml&format_level=full&holdings=true&query=ONR:"
  VALID_KEYS = ["source_name", "source_id", "catalog_id", "name", "metadata", "title", "author", "object_info", "comment", "flow_id", "flow_params"]

  def self.validate_source_fields(params)
    return true if params[:catalog_id].present?
    false
  end

  # Validates fields of job object
  def self.validate_job_fields(object)
    object.each do |key,value|
      return false if !VALID_KEYS.include? key.to_s
    end
    true
  end

  # Returns a hash of data fetched from source
  def self.fetch_source_data(catalog_id, extra_params={})
    url = URI.parse(LIBRIS_XSEARCH_MARC+catalog_id.to_s)
    job_data = {}
    job_data = fetch_from_libris(url)
    job_data[:catalog_id] = catalog_id if not job_data.blank?
    return job_data
  end

  private

  def self.fetch_from_libris(url)
    job_data = {}
    open(url) do |conn|
      librisdata = conn.read
      job_data = data_from_record(librisdata)
      job_data[:xml] = librisdata if not job_data.blank?
    end
    return job_data
  end

  def self.data_from_record(librisdata)
    librisdoc = Nokogiri::XML(librisdata)
    librisdoc.remove_namespaces!
    record = librisdoc.search("/xsearch/collection/record").first
    job_data = {}
    if (record)
      marc_record = MARC::XMLReader.new(StringIO.new(record.to_xml)).first
      job_data[:title] = [marc_record['245']['a'],marc_record['245']['b'],marc_record['245']['p'],marc_record['245']['n']].compact.join(" ")
      job_data[:author] = marc_record['100']['a'] if marc_record['100']
      job_data[:metadata] = {}
      job_data[:metadata][:type_of_record] =  marc_record.leader[6..7]
      job_data[:metadata][:language] = "swe"
      if (marc_record['260'] && marc_record['260']['c'])
        year = marc_record['260']['c'].gsub(/[^\d]/,'').to_i
        future_date = DateTime.now + 5.years
        if year >= 1000 && year < future_date.year
          job_data[:metadata][:year] = year
        end
      end
      job_data[:source_name] = Source.find_name_by_class_name(self.name)
      job_data[:source_label] = Source.find_label_by_name(job_data[:source_name])
      job_data[:is_periodical] = is_periodical(job_data[:metadata][:type_of_record])
    end
    return job_data
  end

  def self.source_link(id)
    return "http://libris.kb.se/bib/#{id}"
  end

  # Returns true if given type is a subset of a periodical
  def self.is_periodical(type_of_record)
    ['as', 'cs'].include?(type_of_record)
  end

  def self.has_types(sheet)
    column_names = []
    sheet.to_a.each.with_index do |row,i|

      # Read the column names in the first rowvalidate_job_fields
      if i == 0
        column_names = row
        next
      end

      # Ignore the 2nd and 3rd rows (placeholders for info about the spreadsheet)
      next if i <= 2

      # Ignore any empty rows
      next if row.compact.empty?

      # Ignore rows which are explicitly marked to be skipped (ignored)
      next if ignore_row?(row, column_names)

      # Check if the type is not present
      return false if find_cell(row, 'type', column_names).blank?
    end
    return true
  end

  def self.find_duplicates(sheet)
    column_names = []
    duplicates = []
    sheet.to_a.each.with_index do |row,i|

      # Read the column names in the first rowvalidate_job_fields
      if i == 0
        column_names = row
        next
      end

      # Ignore the 2nd and 3rd rows (placeholders for info about the spreadsheet)
      next if i <= 2

      # Ignore any empty rows
      next if row.compact.empty?

      # Ignore rows which are explicitly marked to be skipped (ignored)
      next if ignore_row?(row, column_names)

      # Ignore rows for certain types
      next if skip_duplicate_check?(row, column_names)

      # Check if the libris catalog id already exists in the system
      catalog_id = find_cell(row, 'catalog_id', column_names).to_s
      if !Job.where(['catalog_id = ? and source = ?', catalog_id, 'libris']).empty?
        duplicates << catalog_id
      end
    end
    # Philosophical question: How can duplicates be unique?
    return duplicates.uniq
    # Philosofical answer: Context is everything!
  end

private

  def self.find_cell(row, column_name, column_names)
    row[column_names.index(column_name)]
  end

  def self.ignore_row?(row, column_names)
    column_names.include?('ignore') && row[column_names.index('ignore')].present?
  end

  def self.skip_duplicate_check?(row, column_names)
    column_names.include?('type') && row[column_names.index('type')].downcase.eql?("s")
  end

end

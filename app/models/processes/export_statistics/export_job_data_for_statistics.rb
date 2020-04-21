require 'spreadsheet'
require 'stringio'

class ExportJobDataForStatistics

  # When the life span expires the requested Excel file can no longer be downloaded
  EXCEL_LIFE_SPAN_IN_REDIS              ||= 8.hour

  # The date format of the Excel file date columns
  EXCEL_DATE_FORMAT                     ||= 'YYYY-MM-DD'

  # The column numbers are the same in the Excel file as in the database
  # (The user interface of course shows letters instead of numbers for the columns)

  NUMBER_OF_COLUMNS                     ||= 22

  # Special columns regarding formatting, i.e. not ordinary text
  COLUMN_NUMBER_JOB_ID                  ||=  0 # A  0 Integer
  COLUMN_NUMBER_IMAGE_COUNT             ||=  8 # I  8 Integer
  COLUMN_NUMBER_TIMESTAMP_JOB_STARTED   ||= 19 # T 19 Textified date > date
  COLUMN_NUMBER_TIMESTAMP_DIG_FINISHED  ||= 20 # U 20 Textified date > date
  COLUMN_NUMBER_TIMESTAMP_JOB_FINISHED  ||= 21 # V 21 Textified date > date (Time limitation field)
  COLUMN_NUMBER_RESTARTED               ||=  1 # B  1 Text (yes/no)
  COLUMN_NUMBER_COPYRIGHT               ||=  6 # G  6 Text (yes/no)

  # Column groups"
  COLUMN_INTERVAL_JOB_ID                ||=  0..0
  COLUMN_INTERVAL_JOB_STATUS            ||=  1..1
  COLUMN_INTERVAL_PRIMARY_JOB_TYPE_INFO ||=  2..7
  COLUMN_INTERVAL_SCANNING_INFO         ||=  8..11
  COLUMN_INTERVAL_IDENTIFICATION_INFO   ||= 12..15
  COLUMN_INTERVAL_SECONDARY_JOB_INFO    ||= 16..18
  COLUMN_INTERVAL_TIMESTAMPS            ||= 19..21

  # Translation from the database view column names to the Excel file column names
  COLUMN_TITLES ||= {
    # ----- Job ID ----
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_JOB_ID                 => 'Jobb-id',             # A  0 Integer
    # ----- Job status -----
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_RESTARTED              => 'Omstartat',           # B  1 Text (yes/no)
    # ----- Primary job type info -----
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_TYPE_OF_RECORD         => 'Materialkategori',    # C  2 Text
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_PUBLICATION_TYPES      => 'Publikationstyper',   # D  3 Text
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_GUPEA_COLLECTION       => 'Gupeasamling',        # E  4 Text (Integer/{})
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_ALVIN_ID               => 'Alvin-id',            # F  5 Text (Integer/{})
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_COPYRIGHT              => 'Copyright',           # G  6 Text (yes/no)
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_SOURCE                 => 'Källa',               # H  7 Text
    # ----- Scanning info -----
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_IMAGE_COUNT            => 'Bildantal',           # I  8 Integer
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_SCANNER_MAKE           => 'Scannertillverkare',  # J  9 Text
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_SCANNER_MODEL          => 'Scannermodell',       # K 10 Text
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_SCANNER_SOFTWARE       => 'Programvara',         # L 11 Text
    # ----- Identification info -----
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_FLOW_NAME              => 'Flöde',               # M 12 Text
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_JOB_NAME               => 'Jobbnamn',            # N 13 Text
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_TITLE                  => 'Titel',               # O 14 Text
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_AUTHOR                 => 'Författare',          # P 15 Text
    # ----- Secondary job type info -----
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_LIBRARY                => 'Bibliotek',           # Q 16 Text/{}
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_DELIVERY               => 'Leverans',            # R 17 Text/{}
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_OCR                    => 'OCR',                 # S 18 Text/{}
    # ----- Timestamps -----
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_TIMESTAMP_JOB_STARTED  => 'Jobb startat',        # T 19 Textified date > date
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_TIMESTAMP_DIG_FINISHED => 'Digitalisering klar', # U 20 Textified date > date
    QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_TIMESTAMP_JOB_FINISHED => 'Jobb klart'           # V 21 Textified date > date (Time limitation field)
  }
  
  # Build status indicators sent to the frontend telling how the file build progresses
  BUILD_STATUS_INITIALIZING       ||= 'INITIALIZING'
  BUILD_STATUS_QUERYING_DB        ||= 'QUERYING_DATABASE'
  BUILD_STATUS_DB_QUERIED         ||= 'DATABASE_QUERIED'
  BUILD_STATUS_WORKBOOK_BUILT     ||= 'WORKBOOK_BUILT'
  BUILD_STATUS_XLS_DATA_OUTPUT    ||= 'XLS_DATA_OUTPUT'
  BUILD_STATUS_READY_FOR_DOWNLOAD ||= 'READY_FOR_DOWNLOAD'

  def self.run(logger: nil, process_id:, start_date:, end_date:, file_name:, sheet_name:)

    @redis = ScriptManager.redis

    set_redis_filename(process_id, file_name)
    set_redis_build_status(process_id, BUILD_STATUS_INITIALIZING)

    # [1] Create the time limited query
    query = QueryBuilderJobDataForStatistics.build_time_limited_view_invoking_query(start_date, end_date)

    # [2] Execute the query and get the result into an ActiveRecord::Result object
    # [IMPORTANT!] BEFORE RUNNING THE QUERY ENSURE THE FOLLOWING INDEXES EXIST:
    # * CREATE INDEX idx_job_activities_job_id on job_activities(job_id)
    # * CREATE INDEX idx_job_activities_event on job_activities(event)
    set_redis_build_status(process_id, BUILD_STATUS_QUERYING_DB)
    query_result = ActiveRecord::Base.connection.exec_query(query)
    set_redis_build_status(process_id, BUILD_STATUS_DB_QUERIED)

    # [3] Convert the result of the query to (a worksheet of) an Excel workbook
    workbook = build_workbook_from_query_result(query_result, sheet_name)
    set_redis_build_status(process_id, BUILD_STATUS_WORKBOOK_BUILT)

    # [4] Write the workbook to output
    xls_data = StringIO.new
    workbook.write(xls_data)
    set_redis_build_status(process_id, BUILD_STATUS_XLS_DATA_OUTPUT)

    # [5] Copy the output to redis
    set_redis_xls_data(process_id, xls_data.string)
    set_redis_build_status(process_id, BUILD_STATUS_READY_FOR_DOWNLOAD)

  end

 private
 
  def self.build_workbook_from_query_result(query_result, sheet_name)
    
    # Create an Excel workbook and prepare a sheet for the query result 
    Spreadsheet.client_encoding = 'UTF-8'
    workbook = Spreadsheet::Workbook.new
    the_one_and_only_sheet = workbook.create_worksheet(name: sheet_name)
    preformat_sheet(the_one_and_only_sheet)

    # Populate the sheet with the results from the query
    # [1] Column titles
    column_titles = query_result.columns.map { |name| COLUMN_TITLES[name] }
    the_one_and_only_sheet.row(0).concat(column_titles)
    # [2] Result rows (one per job)
    rows = query_result.rows
    rows.each.with_index(1) do |row, index|
      the_one_and_only_sheet.insert_row(index, convert_values_if_necessary(row))
    end

    format_sheet(the_one_and_only_sheet)

    workbook
  end

  def self.preformat_sheet(sheet)
    # Preformatting the date columns seems to increase the chance that their width 
    # adapts to the contents instead of hash signs being diplayed in the cell when 
    # the sheet is first opened
    date_format = Spreadsheet::Format.new number_format: EXCEL_DATE_FORMAT
    sheet.column(COLUMN_NUMBER_TIMESTAMP_JOB_STARTED) .default_format = date_format
    sheet.column(COLUMN_NUMBER_TIMESTAMP_DIG_FINISHED).default_format = date_format
    sheet.column(COLUMN_NUMBER_TIMESTAMP_JOB_FINISHED).default_format = date_format
  end

  def self.format_sheet(sheet)

    # Formats
    # For colors: "http://www.softwaremaniacs.net/2013/11/setting-cell-color-using-ruby.html"
    header_format   = Spreadsheet::Format.new(pattern: 1, pattern_fg_color: :xls_color_48, 
                                              right: :hair, bottom: :hair, 
                                              weight: :bold, color: :white)
    light_yellow_bg = Spreadsheet::Format.new(pattern: 1, pattern_fg_color: :xls_color_18, 
                                              right: :hair, bottom: :hair)
    silver_bg       = Spreadsheet::Format.new(pattern: 1, pattern_fg_color: :xls_color_14, 
                                              right: :hair, bottom: :hair)
    date_bg         = Spreadsheet::Format.new(pattern: 1, pattern_fg_color: :xls_color_18, 
                                              right: :hair, bottom: :hair, 
                                              number_format: EXCEL_DATE_FORMAT)

    # Header cells
    NUMBER_OF_COLUMNS.times do | column_number |
      sheet.row(0).set_format(column_number, header_format)
    end

    # Value cells
    non_header_rows_indexes = 1..(sheet.last_row_index)
    formats_in_order        = [light_yellow_bg, silver_bg, 
                               light_yellow_bg, silver_bg, 
                               light_yellow_bg, silver_bg, date_bg]
    non_header_rows_indexes.each do | row_number |
      COLUMN_INTERVAL_JOB_ID.each                do | column_number |
        sheet.row(row_number).set_format(column_number, formats_in_order[0])
      end
      COLUMN_INTERVAL_JOB_STATUS.each            do | column_number |
        sheet.row(row_number).set_format(column_number, formats_in_order[1])
      end
      COLUMN_INTERVAL_PRIMARY_JOB_TYPE_INFO.each do | column_number |
        sheet.row(row_number).set_format(column_number, formats_in_order[2])
      end
      COLUMN_INTERVAL_SCANNING_INFO.each         do | column_number |
        sheet.row(row_number).set_format(column_number, formats_in_order[3])
      end
      COLUMN_INTERVAL_IDENTIFICATION_INFO.each   do | column_number |
        sheet.row(row_number).set_format(column_number, formats_in_order[4])
      end
      COLUMN_INTERVAL_SECONDARY_JOB_INFO.each    do | column_number |
        sheet.row(row_number).set_format(column_number, formats_in_order[5])
      end
      COLUMN_INTERVAL_TIMESTAMPS.each            do | column_number |
        sheet.row(row_number).set_format(column_number, formats_in_order[6])
      end
    end

  end

  def self.convert_values_if_necessary(row)
    row[COLUMN_NUMBER_JOB_ID]               = make_nil_safe_int_conversion(row[COLUMN_NUMBER_JOB_ID])
    row[COLUMN_NUMBER_IMAGE_COUNT]          = make_nil_safe_int_conversion(row[COLUMN_NUMBER_IMAGE_COUNT])
    row[COLUMN_NUMBER_TIMESTAMP_JOB_STARTED]  = make_nil_safe_date_parsing(row[COLUMN_NUMBER_TIMESTAMP_JOB_STARTED])
    row[COLUMN_NUMBER_TIMESTAMP_DIG_FINISHED] = make_nil_safe_date_parsing(row[COLUMN_NUMBER_TIMESTAMP_DIG_FINISHED])
    row[COLUMN_NUMBER_TIMESTAMP_JOB_FINISHED] = make_nil_safe_date_parsing(row[COLUMN_NUMBER_TIMESTAMP_JOB_FINISHED])
    row[COLUMN_NUMBER_RESTARTED]         = make_nil_safe_yes_no_conversion(row[COLUMN_NUMBER_RESTARTED])
    row[COLUMN_NUMBER_COPYRIGHT]         = make_nil_safe_yes_no_conversion(row[COLUMN_NUMBER_COPYRIGHT])
    row
  end

  def self.make_nil_safe_int_conversion(value)
    Integer value unless value.nil?
  end

  def self.make_nil_safe_date_parsing(value)
    Date.parse value unless value.nil?
  end

  def self.make_nil_safe_yes_no_conversion(value)
    { 'Yes' => 'Ja',
      'No' => 'Nej',
      nil => '-'
    }[value]
  end

  def self.set_redis_build_status(id, status)
    set_redis("dFlow:scripts:#{id}:build_status", status)
  end

  def self.set_redis_filename(id, filename)
    set_redis("dFlow:scripts:#{id}:filename", filename)
  end

  def self.set_redis_xls_data(id, xls_data)
    set_redis("dFlow:scripts:#{id}:xls_data_as_string", xls_data)
  end

  def self.set_redis(key, value)
    begin 
      @redis.set(key, value)
    rescue  Exception => e
      pp e.message # e.message: "undefined method `    ' for ExportJobDataForStatistics:Class"
    end
  end
end

class QueryBuilderJobDataForStatisticsView

  VIEW_NAME      ||= "job_data_for_statistics"
  INDENT_LENGTH  ||= 2
  AS             ||= "AS"
  NEWLINE        ||= "\n"

  ####################################
  ########## HELPER METHODS ##########

  def self.double_quote(text)
    "\"" + text + "\""
  end

  def self.indent(text, number)
    text.split(NEWLINE)
        .map { |line| line.prepend(' ' * (number * INDENT_LENGTH)) }
        .join(NEWLINE)
  end

  def self.build_target_column_sql(column_title, column_content)
    [ column_content, AS, double_quote(column_title)].join(" ")
  end
  
  ####################################
  ###### TARGET COLUMNS (SELECT) #####

  # ----- Job ID ----
  COLUMN_TITLE_JOB_ID                 ||= 'job_id'            #  0 Integer
  # ----- Job status -----
  COLUMN_TITLE_RESTARTED              ||= 'restarted'         #  1 Text (yes/no)
  # ----- Primary job type info -----
  COLUMN_TITLE_TYPE_OF_RECORD         ||= 'type_of_record'    #  2 Text
  COLUMN_TITLE_PUBLICATION_TYPES      ||= 'publication_types' #  3 Text
  COLUMN_TITLE_GUPEA_COLLECTION       ||= 'gupea_collection'  #  4 Text (integer/{})
  COLUMN_TITLE_ALVIN_ID               ||= 'alvin_id'          #  5 Text (integer/{})
  COLUMN_TITLE_COPYRIGHT              ||= 'copyright'         #  6 Text (yes/no)
  COLUMN_TITLE_SOURCE                 ||= 'source'            #  7 Text
  # ----- Scanning info -----
  COLUMN_TITLE_IMAGE_COUNT            ||= 'image_count'       #  8 Integer
  COLUMN_TITLE_SCANNER_MAKE           ||= 'scanner_make'      #  9 Text
  COLUMN_TITLE_SCANNER_MODEL          ||= 'scanner_model'     # 10 Text
  COLUMN_TITLE_SCANNER_SOFTWARE       ||= 'scanner_software'  # 11 Text
  # ----- Identification info -----
  COLUMN_TITLE_FLOW_NAME              ||= 'flow_name'         # 12 Text
  COLUMN_TITLE_JOB_NAME               ||= 'job_name'          # 13 Text
  COLUMN_TITLE_TITLE                  ||= 'title'             # 14 Text
  COLUMN_TITLE_AUTHOR                 ||= 'author'            # 15 Text
  # ----- Secondary job type info -----
  COLUMN_TITLE_LIBRARY                ||= 'library'           # 16 Text/{}
  COLUMN_TITLE_DELIVERY               ||= 'delivery'          # 17 Text/{}
  COLUMN_TITLE_OCR                    ||= 'ocr'               # 18 Text/{}
  # ----- Timestamps -----
  COLUMN_TITLE_TIMESTAMP_JOB_STARTED  ||= 'job_started'       # 19 Textified date
  COLUMN_TITLE_TIMESTAMP_DIG_FINISHED ||= 'dig_finished'      # 20 Textified date
  COLUMN_TITLE_TIMESTAMP_JOB_FINISHED ||= 'job_finished'      # 21 Textified date (Time limitation field)
  
  PRIMARY_VIEW_ORDER_BY_COLUMN        ||= double_quote(COLUMN_TITLE_TIMESTAMP_JOB_STARTED)

  # ----- Job ID ----
  
  COLUMN_CONTENT_JOB_ID ||= "j.id"
  JOB_ID ||= build_target_column_sql(  COLUMN_TITLE_JOB_ID,
                                     COLUMN_CONTENT_JOB_ID)

  # ----- Job status -----
  
  COLUMN_CONTENT_RESTARTED ||= [
      "(CASE WHEN (SELECT COUNT(*) > 0 as r",
      "              FROM jobs j2 JOIN job_activities a ON j.id = a.job_id",
      "             WHERE a.event = 'RESTART'",
      "               AND j2.id = j.id)",
      "      THEN 'Yes'",
      "      ELSE 'No' END)"
    ].join(NEWLINE)
  RESTARTED ||= build_target_column_sql(  COLUMN_TITLE_RESTARTED,
                                        COLUMN_CONTENT_RESTARTED)

  # ----- Primary job type info -----

  COLUMN_CONTENT_TYPE_OF_RECORD ||= [
      "(CASE WHEN j.metadata <> '' AND j.metadata <> '{}'",
      "      THEN j.metadata::json->>'type_of_record'",
      "      ELSE j.metadata END)" 
    ].join(NEWLINE)
  TYPE_OF_RECORD ||= build_target_column_sql(  COLUMN_TITLE_TYPE_OF_RECORD,
                                             COLUMN_CONTENT_TYPE_OF_RECORD)

  COLUMN_CONTENT_PUBLICATION_TYPES ||= [
      "(SELECT array_to_string(array_agg(distinct pub_type_column),', ')",
      "   FROM",
      "     (SELECT",
      "     (CASE WHEN publication_type = 'GUPEA'",
      "           THEN 'Gupea'",
      "           WHEN publication_type = 'DCAT_LIBRIS_ID'",
      "           THEN 'Libris'",
      "           ELSE '' END) as pub_type_column",
      "           FROM publication_logs px ",
      "           WHERE px.job_id = j.id AND px.publication_type <> 'DCAT_HOLDING_ID') as pub_type_table)"
    ].join(NEWLINE)
  PUBLICATION_TYPES ||= build_target_column_sql(  COLUMN_TITLE_PUBLICATION_TYPES,
                                                COLUMN_CONTENT_PUBLICATION_TYPES)

  COLUMN_CONTENT_GUPEA_COLLECTION ||= [
      "(CASE WHEN j.flow_parameters <> '' AND j.flow_parameters <> '{}'",
      "      THEN j.flow_parameters::json->>'gupeasamling'",
      "      ELSE j.flow_parameters END)"
    ].join(NEWLINE)
  GUPEA_COLLECTION ||= build_target_column_sql(  COLUMN_TITLE_GUPEA_COLLECTION,
                                               COLUMN_CONTENT_GUPEA_COLLECTION)

  COLUMN_CONTENT_ALVIN_ID ||= [
      "(CASE WHEN j.flow_parameters <> '' AND j.flow_parameters <> '{}'",
      "      THEN j.flow_parameters::json->>'alvin-id'",
      "      ELSE j.flow_parameters END)"
    ].join(NEWLINE)
  ALVIN_ID ||= build_target_column_sql(  COLUMN_TITLE_ALVIN_ID,
                                       COLUMN_CONTENT_ALVIN_ID)

  COLUMN_CONTENT_COPYRIGHT ||= [
      "(CASE WHEN j.copyright = TRUE",
      "      THEN 'Yes'",
      "      WHEN j.copyright = FALSE", 
      "      THEN 'No'",
      "      ELSE '-' END)"
    ].join(NEWLINE)
  COPYRIGHT ||= build_target_column_sql(  COLUMN_TITLE_COPYRIGHT,
                                        COLUMN_CONTENT_COPYRIGHT)

  COLUMN_CONTENT_SOURCE ||= "j.source"
  SOURCE ||= build_target_column_sql(  COLUMN_TITLE_SOURCE,
                                     COLUMN_CONTENT_SOURCE)

  # ----- Scanning info -----

  COLUMN_CONTENT_IMAGE_COUNT ||= [
      "(CASE WHEN j.package_metadata <> '' AND package_metadata <> '{}'",
      "      THEN package_metadata::json->>'image_count'",
      "      ELSE '0' END)::integer"
    ].join(NEWLINE)
  IMAGE_COUNT ||= build_target_column_sql(  COLUMN_TITLE_IMAGE_COUNT,
                                          COLUMN_CONTENT_IMAGE_COUNT)

  COLUMN_CONTENT_SCANNER_MAKE ||= "j.scanner_make"
  SCANNER_MAKE ||= build_target_column_sql(  COLUMN_TITLE_SCANNER_MAKE,
                                           COLUMN_CONTENT_SCANNER_MAKE)

  COLUMN_CONTENT_SCANNER_MODEL ||= "j.scanner_model"
  SCANNER_MODEL ||= build_target_column_sql(  COLUMN_TITLE_SCANNER_MODEL,
                                            COLUMN_CONTENT_SCANNER_MODEL)

  COLUMN_CONTENT_SCANNER_SOFTWARE ||= "j.scanner_software"
  SCANNER_SOFTWARE ||= build_target_column_sql(  COLUMN_TITLE_SCANNER_SOFTWARE,
                                               COLUMN_CONTENT_SCANNER_SOFTWARE)

  # ----- Identification info -----
  
  COLUMN_CONTENT_FLOW_NAME ||= "text(f.name)"
  FLOW_NAME ||= build_target_column_sql(  COLUMN_TITLE_FLOW_NAME,
                                        COLUMN_CONTENT_FLOW_NAME)

  COLUMN_CONTENT_JOB_NAME ||= "j.name"
  JOB_NAME ||= build_target_column_sql(  COLUMN_TITLE_JOB_NAME,
                                       COLUMN_CONTENT_JOB_NAME)

  COLUMN_CONTENT_TITLE ||= "j.title"
  TITLE ||= build_target_column_sql(  COLUMN_TITLE_TITLE,
                                    COLUMN_CONTENT_TITLE)

  COLUMN_CONTENT_AUTHOR ||= "j.author"
  AUTHOR ||= build_target_column_sql(  COLUMN_TITLE_AUTHOR,
                                     COLUMN_CONTENT_AUTHOR)
  
  # ----- Secondary job type info -----
  
  COLUMN_CONTENT_DELIVERY ||= [
      "(CASE WHEN j.flow_parameters <> '' AND j.flow_parameters <> '{}'",
      "      THEN j.flow_parameters::json->>'leverans'",
      "      ELSE j.flow_parameters END)"
    ].join(NEWLINE)
  DELIVERY ||= build_target_column_sql(  COLUMN_TITLE_DELIVERY,
                                       COLUMN_CONTENT_DELIVERY)

  COLUMN_CONTENT_LIBRARY ||= [
      "(CASE WHEN j.flow_parameters <> '' AND j.flow_parameters <> '{}'",
      "      THEN j.flow_parameters::json->>'bibliotek'",
      "      ELSE j.flow_parameters END)"
    ].join(NEWLINE)
  LIBRARY ||= build_target_column_sql(  COLUMN_TITLE_LIBRARY,
                                      COLUMN_CONTENT_LIBRARY)

  COLUMN_CONTENT_OCR ||= [
      "(CASE WHEN j.flow_parameters <> '' AND j.flow_parameters <> '{}'",
      "      THEN j.flow_parameters::json->>'ocr'",
      "      ELSE j.flow_parameters END)"
    ].join(NEWLINE)
  OCR ||= build_target_column_sql(  COLUMN_TITLE_OCR,
                                  COLUMN_CONTENT_OCR)

  # ----- Timestamps -----

  COLUMN_CONTENT_TIMESTAMP_JOB_STARTED ||= [
      "to_char(",
      "  (SELECT ax.created_at as job_start_timestamp_column",
      "     FROM job_activities ax",
      "    WHERE ax.job_id = j.id",
      "      AND ax.message IN ('Väntar på digitalisering', 'Väntar på flödesstart', 'Startsteg')",
      "      AND ax.event = 'FINISHED'",
      "    LIMIT 1), 'YYYY-MM-DD')"].join(NEWLINE)
  TIMESTAMP_JOB_STARTED ||= build_target_column_sql(  COLUMN_TITLE_TIMESTAMP_JOB_STARTED,
                                                    COLUMN_CONTENT_TIMESTAMP_JOB_STARTED)

  COLUMN_CONTENT_TIMESTAMP_DIG_FINISHED ||= [
      "to_char(",
      "  (SELECT ax.created_at as digitalization_finished_timestamp_column",
      "     FROM job_activities ax",
      "    WHERE ax.job_id = j.id",
      "      AND ax.message IN ('Digitalisering pågår', 'Digitalisering')",
      "      AND ax.event = 'FINISHED'",
      "    LIMIT 1), 'YYYY-MM-DD')"].join(NEWLINE)
  TIMESTAMP_DIG_FINISHED ||= build_target_column_sql(  COLUMN_TITLE_TIMESTAMP_DIG_FINISHED,
                                                     COLUMN_CONTENT_TIMESTAMP_DIG_FINISHED)

  COLUMN_CONTENT_TIMESTAMP_JOB_FINISHED ||= [
      "to_char(",
      "  (SELECT ax.created_at as job_finished_timestamp_column",
      "     FROM job_activities ax",
      "    WHERE ax.job_id = j.id",
      "      AND ax.username = 'WAIT_FOR_FILE'",
      "      AND ax.event = 'FINISHED'",
      "    LIMIT 1), 'YYYY-MM-DD')"].join(NEWLINE)
  TIMESTAMP_JOB_FINISHED ||= build_target_column_sql(  COLUMN_TITLE_TIMESTAMP_JOB_FINISHED,
                                                     COLUMN_CONTENT_TIMESTAMP_JOB_FINISHED)

  def self.make_title_comment(text)
    NEWLINE + "----- " + text + " -----"
  end

  TARGET_COLUMNS_BLOCK ||= [
      make_title_comment("Job id"),
      JOB_ID,
      make_title_comment("Job status"),
      RESTARTED,
      make_title_comment("Primary job type info"),
      TYPE_OF_RECORD, PUBLICATION_TYPES, GUPEA_COLLECTION, ALVIN_ID, COPYRIGHT, SOURCE,
      make_title_comment("Scanning info"),
      IMAGE_COUNT, SCANNER_MAKE, SCANNER_MODEL, SCANNER_SOFTWARE,
      make_title_comment("Identification info"),
      FLOW_NAME, JOB_NAME, TITLE, AUTHOR,
      make_title_comment("Secondary job type info"),
      LIBRARY, DELIVERY, OCR,
      make_title_comment("Timestamps"),
      TIMESTAMP_JOB_STARTED, TIMESTAMP_DIG_FINISHED, TIMESTAMP_JOB_FINISHED
    ].join("," + NEWLINE)

  #######################################
  ######### SOURCE TABLE (JOIN) #########

  SOURCE_TABLE_BLOCK ||= [
      "jobs j JOIN job_activities   a ON j.id      = a.job_id",
      "       JOIN flows            f ON j.flow_id = f.id",
      "  LEFT JOIN publication_logs p ON j.id      = p.job_id"
    ].join(NEWLINE)

  ########################################
  ###### SOURCE ROW FILTERS (WHERE) ######

  RELEVANT_TIMESTAMPS ||= [
      "----- Only job activities with relevant timestamps are interesting -----",
      "(     a.message  = 'Väntar på digitalisering' AND a.event = 'FINISHED' -- Dig/job starts",
      "   OR a.message  = 'Väntar på flödesstart'    AND a.event = 'FINISHED' -- Dig/job starts",
      "   OR a.message  = 'Startsteg'                AND a.event = 'FINISHED' -- Dig/job starts",
      "   OR a.message  = 'Digitalisering pågår'     AND a.event = 'FINISHED' -- Dig finished",
      "   OR a.message  = 'Digitalisering'           AND a.event = 'FINISHED' -- Dig finished",
      "   OR a.username = 'WAIT_FOR_FILE'            AND a.event = 'FINISHED' -- Job finished",
      ")"
    ].join(NEWLINE)

  REJECT_NON_RELEVANT_FLOW ||= [
      "----- Jobs based on the following flows should be excluded -----",
      "f.name NOT IN ('X_UMEA_TEST',",
      "               'TXT_TEST',",
      "               'X_NEW_OCR_TEST',",
      "               'IMAGEMAGIC_PDF_TEST',",
      "               'X_TEST_FLOW')"
    ].join(NEWLINE)

  REJECT_DELETED_JOBS ||= [
      "----- Jobs not displayed in dFlow should be excluded -----",
      "j.deleted_at IS NULL"
    ].join(NEWLINE)

  STATIC_ROW_FILTER_BLOCK ||= [
      RELEVANT_TIMESTAMPS,
      REJECT_NON_RELEVANT_FLOW,
      REJECT_DELETED_JOBS
    ].join(NEWLINE + indent("AND", 0) + NEWLINE)

  #############################
  ########## QUERIES ##########

  def self.build_view_contents_query()
    indentation = 1
    [ "SELECT DISTINCT",
      indent(TARGET_COLUMNS_BLOCK, indentation), NEWLINE,
      "FROM",
      indent(SOURCE_TABLE_BLOCK, indentation), NEWLINE,
      "WHERE",
      indent(STATIC_ROW_FILTER_BLOCK, indentation),
      ""
    ].join(NEWLINE)
  end
  
  def self.build_view_creation_query(view_name)
    [["CREATE VIEW", view_name, AS].join(" "),
      "",
      build_view_contents_query()].join(NEWLINE)
  end

  def self.prefix_with_drop_view_statement(view_name, create_view_query)
    ["DROP VIEW IF EXISTS #{view_name};",
      "",
      create_view_query].join(NEWLINE)
  end

  def self.build_view_creation_query_including_drop_view()
    prefix_with_drop_view_statement(
        VIEW_NAME, build_view_creation_query(VIEW_NAME))
  end

end

#########################################################################################################

class QueryExecutorJobDataForStatisticsViewCreation
  def self.dryrun
    QueryBuilderJobDataForStatisticsView.
      build_view_creation_query_including_drop_view()
  end
  def self.execute
    ActiveRecord::Base.connection.execute(
      QueryBuilderJobDataForStatisticsView.
        build_view_creation_query_including_drop_view())
  end
end

#########################################################################################################

begin
  puts "Adding '#{QueryBuilderJobDataForStatisticsView::VIEW_NAME}' view to database"
  QueryExecutorJobDataForStatisticsViewCreation.execute
rescue
  puts "An error occurred while trying to add '#{QueryBuilderJobDataForStatisticsView::VIEW_NAME}' view to database"
end

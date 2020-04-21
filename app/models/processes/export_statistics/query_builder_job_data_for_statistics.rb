class QueryBuilderJobDataForStatistics

  VIEW_NAME                           ||= QueryBuilderJobDataForStatisticsView::VIEW_NAME
  COLUMN_SELECTED_FOR_TIME_LIMITATION ||= QueryBuilderJobDataForStatisticsView::COLUMN_TITLE_TIMESTAMP_JOB_FINISHED
  PRIMARY_ORDER_BY_COLUMN             ||= COLUMN_SELECTED_FOR_TIME_LIMITATION
  NEWLINE                             ||= "\n"

  # Example:
  # SELECT *
  #   FROM job_data_for_statistics
  #  WHERE job_finished BETWEEN '2018-01-01' AND '2018-08-31'
  #  ORDER BY job_finished
  def self.build_time_limited_view_invoking_query(start_date, end_date)
    [["SELECT",    "*"                                                                            ].join(" "),
     ["  FROM",    VIEW_NAME                                                                      ].join(" "),
     [" WHERE",    date_interval_filter(COLUMN_SELECTED_FOR_TIME_LIMITATION, start_date, end_date)].join(" "),
     [" ORDER BY", PRIMARY_ORDER_BY_COLUMN                                                        ].join(" ")
    ].join(NEWLINE)
  end

 private

  def self.date_interval_filter(date_column, start_date, end_date)
    [date_column, 'BETWEEN', single_quote(start_date), 'AND', single_quote(end_date)].join(" ")
  end

  def self.single_quote(text)
    "'" + text + "'"
  end

end

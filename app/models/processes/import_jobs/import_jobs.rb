require 'pp'

module Import
  class JobEntry
    attr_accessor :catalog_id
    attr_accessor :job_data
    attr_accessor :job
    attr_accessor :row_num
    
    def initialize(treenode_id:, copyright:, flow_id:, flow_parameters:, columns:, row:, row_num:, source:)
      @treenode_id = treenode_id
      @copyright = copyright
      @flow_id = flow_id
      @flow_parameters = flow_parameters
      @columns = columns
      @row_num = row_num
      @source = source
      fixed_row = row.map do |val|
        if val.is_a? Float
          val.to_i.to_s
        else
          val
        end
      end
      @row_hash = Hash[columns.zip(fixed_row)]

      # Name and catalog id is not part of the same kind of data as the other fields,
      # so these will be extracted separately and deleted from the main hash
      @name = @row_hash["name"]
      @catalog_id = @row_hash["catalog_id"]
      @row_hash.delete("name")
      @row_hash.delete("catalog_id")
    end
  
    def generate_job
      if @source.name == "DublinCore"
        generate_dc_job_data
        @row_hash = {}
      end
      @job_data["name"] = @name if @name
      @job_data["metadata"] ||= {}
      if @job_data[:metadata]
        @job_data["metadata"].merge!(@job_data[:metadata])
        @job_data.delete(:metadata)
      end
      @job_data["metadata"].merge!(@row_hash)
      if @job_data[:source_name]
        @job_data["source"] = @job_data[:source_name].dup
        @job_data.delete(:source_name)
      end
      @job_data.delete(:source_label)
      @job_data.delete(:is_periodical)
      @job_data["treenode_id"] = @treenode_id
      @job_data["copyright"] = @copyright
      @job_data["flow_id"] = @flow_id
      @job_data["flow_parameters"] = @flow_parameters.to_json
      @job_data["metadata"] = @job_data["metadata"].to_json
      @job_data["created_by"] = "import"
      @job = Job.new(@job_data)
    end

    # Generate DC job via DublinCoreXml and return provided job_data
    # as if job was created manually.
    def generate_dc_job_data
      @job_data["name"] = @name if @name
      @row_hash["source"] = @row_hash["dc_source"]
      @row_hash.delete("dc_source")
      @job_data = @source.fetch_source_data(nil, @row_hash)
    end
    
    def valid?
      return false if !@job
      @job.valid?
    end
    
    def errors
      return [] if !@job
      @job.errors
    end
    
    def save
      @job.save
    end
  end
end
  
class ImportJobs
  SLOWDOWN=false
  SLOWBY=0.13
  
  def self.run(logger: nil, process_id:, file_path:, source_name:, treenode_id:, copyright:, flow_id:, flow_parameters: {})
    @source_data = {}
    @source = Source.find_by_name(source_name)
    @process_id = process_id
    @jobs = []
    @redis = ScriptManager.redis
    
    begin
      excel_file_data = DfileApi.download_file(source_file: file_path)
    rescue OpenURI::HTTPError
      @redis.set("dFlow:scripts:#{@process_id}:state", "ABORTED")
      @redis.set("dFlow:scripts:#{@process_id}:action", "FILE_ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:type", "ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:message", "Could not load file #{file_path}")
      return
    end
    Spreadsheet.client_encoding = 'UTF-8'
    begin
      excel_file = Spreadsheet.open(excel_file_data)
    rescue
      @redis.set("dFlow:scripts:#{@process_id}:state", "ABORTED")
      @redis.set("dFlow:scripts:#{@process_id}:action", "EXCEL_ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:type", "ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:message", "Could not open file #{file_path}, not an Excel file?")
      return
    end
    sheet = excel_file.worksheet(0)
    
    row_count = sheet.to_a.count
    
    @redis.set("dFlow:scripts:#{@process_id}:state", "RUNNING")
    @redis.set("dFlow:scripts:#{@process_id}:count", 0)
    sheet.to_a.each.with_index do |row,i| 
      # First line has column names
      if i == 0
        @columns = row
        next
      end
      
      # Two more lines are placeholders for information about spreadsheet, and needs to be ignored
      next if i <= 2

      # Ignore empty rows
      next if row.compact.empty?

      @jobs << Import::JobEntry.new(treenode_id: treenode_id,
                                copyright: copyright,
                                flow_id: flow_id,
                                flow_parameters: flow_parameters,
                                columns: @columns,
                                row: row,
                                row_num: i+1,
                                source: @source)
      
      @redis.set("dFlow:scripts:#{@process_id}:action", "PROCESSING_ROW")
      @redis.set("dFlow:scripts:#{@process_id}:type", "INFO")
      @redis.set("dFlow:scripts:#{@process_id}:message", "Processed #{i+1} of #{row_count}")
      sleep SLOWBY if SLOWDOWN
    end
    @redis.set("dFlow:scripts:#{@process_id}:count", @jobs.count)
      
    # Download data from source, and catch potential errors
    source_error = false
    source_error_ids = []
    @catalog_ids = @jobs.map(&:catalog_id).uniq
    @source_data = {}
    @catalog_ids.each do |catalog_id| 
      begin
        @source_data[catalog_id] = @source.fetch_source_data(catalog_id)
      rescue
        @source_data[catalog_id] = {}
      end
      @redis.set("dFlow:scripts:#{@process_id}:action", "FETCHING_SOURCE_DATA")
      @redis.set("dFlow:scripts:#{@process_id}:type", "INFO")
      @redis.set("dFlow:scripts:#{@process_id}:message", "Fetching data from #{source_name} (id: #{catalog_id})")
      
      if @source_data[catalog_id].blank?
        source_error = true
        source_error_ids << catalog_id
        pp "ERROR in source for #{catalog_id}"
      end
      sleep SLOWBY if SLOWDOWN
    end
    
    # If source errors occured, set error in redis and abort.
    if source_error
      @redis.set("dFlow:scripts:#{@process_id}:state", "ABORTED")
      @redis.set("dFlow:scripts:#{@process_id}:action", "SOURCE_ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:type", "ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:message", "Error in catalog id(s): #{source_error_ids.inspect}")
      return
    end
    
    # If no source errors occured, generate jobs based on fetched source data
    # and validate them.
    #
    # If validation passes for all jobs, save them to database.
    @jobs.each.with_index do |job,i| 
      job.job_data = Marshal.load(Marshal.dump(@source_data[job.catalog_id]))
      job.generate_job
      @redis.set("dFlow:scripts:#{@process_id}:action", "GENERATING_JOBS")
      @redis.set("dFlow:scripts:#{@process_id}:type", "INFO")
      @redis.set("dFlow:scripts:#{@process_id}:message", "Generating job #{i+1} of #{@jobs.count}")
      sleep SLOWBY if SLOWDOWN
    end

    job_error = false
    @jobs.each.with_index do |job,i| 
      @redis.set("dFlow:scripts:#{@process_id}:action", "VALIDATING_JOBS")
      @redis.set("dFlow:scripts:#{@process_id}:type", "INFO")
      @redis.set("dFlow:scripts:#{@process_id}:message", "Validating job #{i+1} of #{@jobs.count}")
      if job.valid?
        @redis.set("dFlow:scripts:#{@process_id}:job_state:#{i}", "OK")
      else
        @redis.set("dFlow:scripts:#{@process_id}:job_state:#{i}", "ERROR")
        @redis.set("dFlow:scripts:#{@process_id}:job_error:#{i}:location", job.row_num)
        @redis.set("dFlow:scripts:#{@process_id}:job_error:#{i}:message", job.errors.messages)
        job_error = true
      end
      sleep SLOWBY if SLOWDOWN
    end

    # If any job fails validation, set a proper state and abort.
    if job_error
      @redis.set("dFlow:scripts:#{@process_id}:state", "ABORTED")
      @redis.set("dFlow:scripts:#{@process_id}:action", "JOB_ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:type", "ERROR")
      @redis.set("dFlow:scripts:#{@process_id}:message", "One or more jobs invalid")
      return
    end
    Job.transaction do 
      @jobs.each.with_index do |job,i| 
        @redis.set("dFlow:scripts:#{@process_id}:action", "SAVING_JOBS")
        @redis.set("dFlow:scripts:#{@process_id}:type", "INFO")
        @redis.set("dFlow:scripts:#{@process_id}:message", "Saving job #{i+1} of #{@jobs.count}")
        job.save
        sleep SLOWBY if SLOWDOWN
      end
    end
    @redis.set("dFlow:scripts:#{@process_id}:state", "DONE")
    @redis.set("dFlow:scripts:#{@process_id}:action", "SAVED_JOBS")
    @redis.set("dFlow:scripts:#{@process_id}:type", "INFO")
    @redis.set("dFlow:scripts:#{@process_id}:message", "Saved #{@jobs.count } jobs")
  end
  
  def self.status(process_id:)
    redis = ScriptManager.redis
    
    successful = 0
    error = []
    
    job_count = redis.get("dFlow:scripts:#{process_id}:count").to_i
    job_count.times do |i| 
      if redis.get("dFlow:scripts:#{process_id}:job_state:#{i}") == "OK"
        successful += 1
      elsif redis.get("dFlow:scripts:#{process_id}:job_state:#{i}") == "ERROR"
        error << {
          location: redis.get("dFlow:scripts:#{process_id}:job_error:#{i}:location"),
          message: redis.get("dFlow:scripts:#{process_id}:job_error:#{i}:message")
        }
      end
    end
    
    return {
      successful: successful,
      error: error
    }
  end
end

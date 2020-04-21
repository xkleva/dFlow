Dir[Rails.root.join("app/models/processes/**/*.rb")].each { |f| require f }

class ScriptManagerRedis
  def initialize
    @redis = Redis.new(db: APP_CONFIG['redis_db']['db'], host: APP_CONFIG['redis_db']['host'])
  end

  def get(*args)
    @redis.get(*args)
  end
  
  def set(key, value, ttl = 1.week)
    @redis.set(key, value)
    @redis.expire(key, ttl)
  end
  
  def incr(*args)
    @redis.incr(*args)
  end
  
  def show_all
    @redis.keys.map do |key| 
      {key => @redis.get(key)}
    end
  end
  
  def flushdb
    @redis.flushdb
  end
  
  def reconnect
    @redis = Redis.new(db: APP_CONFIG['redis_db']['db'], host: APP_CONFIG['redis_db']['host'])
  end
end

class ScriptManager
  def self.run(process_name:, params:)
    process_id = redis.incr("dFlow:scripts:process_id")

    if defined?(Rails::Console)
      execute_process(process_name: process_name, process_id: process_id, params: params)
      return process_id
    end
    if !fork
      redis.reconnect
      execute_process(process_name: process_name, process_id: process_id, params: params)
    else
      return process_id
    end
  end

  def self.execute_process(process_name:, process_id:, params:)
    case process_name
    when "IMPORT_JOBS"
      redis.set("dFlow:scripts:#{process_id}:class", "ImportJobs")
      redis.set("dFlow:scripts:#{process_id}:params", params)
      process_runner(process_object: ImportJobs, process_id: process_id, params: params)
    when "EXPORT_JOB_DATA_FOR_STATISTICS"
      redis.set("dFlow:scripts:#{process_id}:class", "ExportJobDataForStatistics")
      redis.set("dFlow:scripts:#{process_id}:params", params)
      process_runner(process_object: ExportJobDataForStatistics, process_id: process_id, params: params)
    else
      redis.set("dFlow:scripts:#{process_id}:state", "ABORTED")
      redis.set("dFlow:scripts:#{process_id}:action", "execute_process")
      redis.set("dFlow:scripts:#{process_id}:type", "ERROR")
      redis.set("dFlow:scripts:#{process_id}:error", "Couldn't find process #{process_name}")
      logger.fatal "Couldn't find process #{process_name}!"
    end
  end
  
  # Runs a given process for a given job
  def self.process_runner(process_object:, process_id:, logger: self.logger, params: {})
    params = params.symbolize_keys
    params[:logger] = logger
    params[:process_id] = process_id
    redis.set("dFlow:scripts:#{process_id}:state", "STARTED")
    process_object.run(params.except!(:start, :end))
  rescue StandardError => e
    redis.set("dFlow:scripts:#{process_id}:state", "ABORTED")
    redis.set("dFlow:scripts:#{process_id}:action", "process_runner")
    redis.set("dFlow:scripts:#{process_id}:type", "ERROR")
    redis.set("dFlow:scripts:#{process_id}:message", "#{e.message} #{e.backtrace.inspect}")
    logger.fatal e.message + " " + e.backtrace.inspect
  end

  # Creates a logger object
  def self.logger
    #@@logger ||= Logger.new(STDOUT)
    @@logger ||= Logger.new("#{Rails.root}/log/script_manager.log")
    @@logger.level = ENV['LOG_LEVEL'].to_i || Logger::INFO
    @@logger
  end
  
  def self.redis
    @@redis ||= ScriptManagerRedis.new
  end
  
  def self.process_status(process_id:)
    class_name = redis.get("dFlow:scripts:#{process_id}:class")
    if !class_name
      return {errors: [:process, "Invalid process ID"]}
    end
    process = Kernel.const_get(class_name)
    pstate = redis.get("dFlow:scripts:#{process_id}:state")
    ptype = redis.get("dFlow:scripts:#{process_id}:type")
    paction = redis.get("dFlow:scripts:#{process_id}:action")
    pmessage = redis.get("dFlow:scripts:#{process_id}:message")
    
    pdata = process.status(process_id: process_id)

    return {
      class_name: class_name,
      state: pstate,
      type: ptype,
      action: paction,
      message: pmessage,
      data: pdata
    }
  end
  
  def self.param_error_check(process_name:, params:)
    process_object = (SYSTEM_DATA["processes"].find { |x| x["code"] == process_name}) || {}
    
    errors = {}
    
    if process_object && process_object["required_params"]
      process_object["required_params"].each do |param|
        if !params.compact.has_key?(param)
          errors[param] ||= []
          errors[param] << "Missing mandatory parameter"
        end
      end
    end
    return errors
  end
end

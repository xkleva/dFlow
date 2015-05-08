# Base class for FileAdapters
# Used by calling FileAdapter.method_name

class FileAdapter
  def self.adapter
    @@adapter_object ||= nil
    return @@adapter_object if @@adapter_object
    case APP_CONFIG['file_adapter']
    when 'dfile'
      file_adapter = DfileAdapter.new(base_url: APP_CONFIG['dfile_base_url'])
    else
      file_adapter = DfileAdapter.new(base_url: APP_CONFIG['dfile_base_url'])
    end      
    @@adapter_object ||= file_adapter
  end

  def self.method_missing(method, *args)
    FileAdapter.adapter.errors = {} unless method == :errors
    FileAdapter.adapter.send(method, *args)
  end
end


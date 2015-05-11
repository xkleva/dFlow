# File Adapter for dFile specifically.
# dFile is found at http://www.github.com/ub-digit/dFile

require 'open-uri'

class DfileAdapter
  attr_accessor :errors

  def initialize(base_url:)
    @base_url = base_url
  end

  # Generates an api_url based on method, format and parameters
  def api_url(method, params: {})
    full_method = method.to_s
    if params[:format]
      full_method += ".#{params[:format]}" 
      params.delete(:format)
    end
    url = URI.parse("#{@base_url}#{full_method}")
    params['api_key'] = APP_CONFIG['dfile_api_key']
    url.query = params.to_param
    url.to_s
  end

  # Checks if file exists based on root location (i.e. STORE, PACKAGING) and path (i.e. /12345/pdf/12345.pdf)
  def file_exists?(location, path)
    source_file = "#{location}:#{path}"
    url = api_url(:download_file, params: {format: :json, source_file: source_file})
    begin
      open(url.to_s) do |u| 
      end
      return true
    rescue OpenURI::HTTPError
      return false
    end
  end

  # Returns file contents based on root location (i.e. STORE, PACKAGING) and path (i.e. /12345/pdf/12345.pdf)
  def open_file(location, path)
    source_file = "#{location}:#{path}"
    url = api_url(:download_file, params: {source_file: source_file})
    open(url)
  end

  # Moves a folder to trash location
  def move_to_trash(location, path)
    source_dir = "#{location}:#{path}"
    url = api_url(:move_to_trash, params: {source_dir: source_dir})
    response = HTTParty.get(url)
    if response.success?
      return true
    else
      return false
    end
  end

  # Returns a list of files including catalog structure based on location
  def files_list(location, path)
    source_dir = "#{location}:#{path}"
    url = api_url(:list_files, params: {source_dir: source_dir, show_catalogues: true})
    response = HTTParty.get(url)
    if response.success?
      return response
    else
      return response
    end
  end
end

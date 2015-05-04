require 'open-uri'

class DfileAdapter
  def initialize(base_url:)
    @base_url = base_url
  end

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

  def open_file(location, path)
    source_file = "#{location}:#{path}"
    url = api_url(:download_file, params: {source_file: source_file})
    open(url)
  end
end

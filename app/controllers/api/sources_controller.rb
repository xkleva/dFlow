
class Api::SourcesController < Api::ApiController

  resource_description do
    short 'Source object manager - Objects responsible for fetching data as basis for Job creation'
  end

  api :GET, '/sources', 'Returns a list of all available sources'
  def index
    @response[:sources] = SYSTEM_DATA["sources"]
    if @response[:sources].nil?
      error_msg(ErrorCodes::REQUEST_ERROR, "Could not find any sources")
    end
    render_json
  end

  # Renders JSON with source data for an item with the given catalog_id from a source with the given source_name.
  api :GET, 'sources/fetch_source_data', 'Returns a source object based on given source name and catalog id.'
  param :catalog_id, String, desc: "Identifier of catalog data to be imported."
  param :name, String, desc: 'Name of source, used as identifier', required: true
  param :dc, Hash, desc: 'Hash with DC fields, in case catalog post does not exist.'
  def fetch_source_data
    catalog_id = params[:catalog_id]
    source_name = params[:name]
    dc_params = params[:dc] ||= {}

    # Identify source object
    source_object = Source.find_by_name(source_name)
    if !source_object
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find a source with name #{source_name}")
      render_json
      return
    end
    if !source_object.validate_source_fields(params)
      error_msg(ErrorCodes::VALIDATION_ERROR, "Required fields missing")
      render_json
      return
    end

    job = Job.find_by_catalog_id(catalog_id)
    # If a job whith this catalog id exists in dFlow, check the item type in the metadata field
    is_monograph = job.present? && JSON.parse(job.metadata)["type_of_record"] && JSON.parse(job.metadata)["type_of_record"][1].eql?("m")

    duplicate = is_monograph && !Job.where(["catalog_id = ? and source = ?", catalog_id, source_name]).empty?

    # Fetch source data
    # Now here we should delegate to the source_object to deal with the params
    # since the params depends on source type.
    source_data = source_object.fetch_source_data(catalog_id, dc_params)
    if source_data && !source_data.empty?
      @response[:source] = source_data.merge({duplicate: duplicate})
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find source data for source: #{source_name} and catalog_id: #{catalog_id}")
    end
    render_json
  end
end

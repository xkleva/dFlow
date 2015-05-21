
class Api::SourcesController < Api::ApiController

  resource_description do
    short 'Source object manager - Objects responsible for fetching data as basis for Job creation'
  end

  api!
	def index
		@response[:sources] = APP_CONFIG["sources"]

		if @response[:sources].nil?
			error_msg(ErrorCodes::REQUEST_ERROR, "Could not find any sources")
		end
		render_json
	end

	# Renders JSON with source data for an item with the given catalog_id from a source with the given source_name.
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

		# Fetch source data
    # Now here we should delegate to the source_object to deal with the params
    # since the params depends on source type.
		source_data = source_object.fetch_source_data(catalog_id, dc_params)

		if source_data && !source_data.empty?
			@response[:source] = source_data
		else
			error_msg(ErrorCodes::OBJECT_ERROR, "Could not find source data for source: #{source_name} and catalog_id: #{catalog_id}")
		end
		render_json
	end

end

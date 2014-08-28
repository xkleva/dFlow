
class Api::SourcesController < Api::ApiController
	before_filter :check_key

	# Validates a list of objects with sources, and returns the validated data with a list of unique catalog_ids
	# valid format is {objects: [{source_name: "String", catalog_id: int, <extra object parameters to be validated>}]}
	def validate_new_objects
		objects = params[:objects]
		if objects.empty?
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("REQUEST_ERROR", "No valid objects are given")
			render json: @response
			return
		end
		success = 0
		fail = 0
		catalog_ids = []
		objects.each do |object|

			# Validate source name
			source_object = Source.where(classname: object[:source_name]).first
			if !source_object
				object[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find a source with name '#{object[:source_name]}")
				fail += 1
				next
			end

			# Validate other parameters
			if !source_object.validate_job_fields(object)
				object[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("VALIDATION_ERROR", "Could not validate given fields")
				fail += 1
				next
			end

			# If catalog_id is new, store it
			catalog_id = object[:catalog_id]
			if !catalog_ids.include? catalog_id
				catalog_ids << catalog_id
			end

			object[:source_id] = source_object.id
			success += 1
		end
		@response[:data] = {}
		@response[:data][:objects] = objects
		@response[:data][:catalog_ids] = catalog_ids
		if fail > 0
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "A number of objects did not validate: #{fail} / #{success+fail}")
		else
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
		end

		render json: @response
	end

	# Returns hash with source data for a given source and catalog_id
	def fetch_source_data
		catalog_id = params[:catalog_id]
		source_id = params[:source_id]

		# Identify source object
		source_object = Source.find_by_id(source_id)
		if !source_object
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find a source with id '#{source_id}")
			render json: @response
			return
		end

		# Fetch source data
		source_data = source_object.fetch_source_data(catalog_id)
		if source_data && !source_data.empty?
			@response[:status] = ResponseData::ResponseStatus.new("SUCCESS")
			@response[:data] = source_data
		else
			@response[:status] = ResponseData::ResponseStatus.new("FAIL").set_error("OBJECT_ERROR", "Could not find source data for source: '#{source_id} and catalog_id: #{catalog_id}")
		end
		render json: @response
	end

end
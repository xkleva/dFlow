# Contains classes for managing response codes and messages
module ResponseData
	class ResponseStatus
		attr_accessor :code,:error

		# Creates a response object from string code value (i.e. "SUCCESS")
		def initialize(code)
			@code = ResponseCodes.const_get(code.upcase)
		end

		# Creates an error object if applicable to response based on:
		# Code (i.e. "VALIDATION_ERROR" - defined in module ErrorCodes)
		# msg (i.e. "Validation failed")
		# error_list (list of error objects)
		def set_error(code, msg, error_list = nil)
			@error = ResponseError.new(code,msg, error_list)
			return self
		end
	end

	# Defines an error object which is returned as json through API methods
	# Error codes are defined in module ErrorCodes
	class ResponseError
		attr_accessor :code, :msg, :error_list, :http_status

		def initialize(code, msg, error_list = nil)
			@code = ErrorCodes.const_get(code.upcase)[:status_code]
			@http_status = ErrorCodes.const_get(code.upcase)[:http_status]
			@msg = msg
			@error_list = error_list
		end
	end
end

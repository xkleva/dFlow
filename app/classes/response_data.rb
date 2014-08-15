# Contains classes for managing response codes and messages
module ResponseData
	class ResponseStatus
		attr_accessor :code,:error

		def initialize(code)
			@code = ResponseCodes.const_get(code.upcase)
		end

		def set_error(code, msg, error_list = nil)
			@error = ResponseError.new(code,msg, error_list)
			return self
		end
	end

	class ResponseError
		attr_accessor :code, :msg, :error_list

		def initialize(code, msg, error_list = nil)
			@code = ErrorCodes.const_get(code.upcase)
			@msg = msg
			@error_list = error_list
		end
	end
end
# Contains classes for managing response codes and messages
module ResponseData
	class ResponseStatus
		attr_accessor :code,:error

		def initialize(code)
			@code = ResponseCodes.const_get(code.upcase)
		end

		def set_error(code,msg)
			@error = ResponseError.new(code,msg)
			return self
		end
	end

	class ResponseError
		attr_accessor :code, :msg

		def initialize(code, msg)
			@code = ErrorCodes.const_get(code.upcase)
			@msg = msg
		end
	end
end
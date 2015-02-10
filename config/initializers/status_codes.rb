# Contains high level repsonse codes
module ResponseCodes
	SUCCESS = 0
	FAIL = -1
end

# Contains error codes and their http response codes
module ErrorCodes
	# Generic error code
	ERROR = {
		http_status: 404,
		status_code: 100,
		code: "ERROR"
	}

	# Used for authentication errors (i.e. needs admin rights)
	AUTH_ERROR = {
		http_status: 404,
		status_code: 101,
		code: "AUTH_ERROR"
	}

	# Used when data cannot be retrieved (i.e. error in request or database)
	DATA_ACCESS_ERROR = {
		http_status: 404,
		status_code: 102,
		code: "DATA_ACCESS_ERROR"
	}

	# Generic object error
	OBJECT_ERROR = {
		http_status: 404,
		status_code: 103,
		code: "OBJECT_ERROR"
	}

	# Used when a flow process step cannot be completed due to its' current state
	QUEUE_ERROR = {
		http_status: 404,
		status_code: 104,
		code: "QUEUE_ERROR"
	}

	# Used when requested data could not be returned
	REQUEST_ERROR = {
		http_status: 404,
		status_code: 105,
		code: "REQUEST_ERROR"
	}

	# Used when object validation fails
	VALIDATION_ERROR = {
		http_status: 404,
		status_code: 106,
		code: "VALIDATION_ERROR"
	}
end

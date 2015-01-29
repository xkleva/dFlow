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
		status_code: 100
	}

	# Used for authentication errors (i.e. needs admin rights)
	AUTH_ERROR = {
		http_status: 404,
		status_code: 101
	}

	# Used when data cannot be retrieved (i.e. error in request or database)
	DATA_ACCESS_ERROR = {
		http_status: 404,
		status_code: 102
	}

	# Generic object error
	OBJECT_ERROR = {
		http_status: 404,
		status_code: 103
	}

	# Used when a flow process step cannot be completed due to its' current state
	QUEUE_ERROR = {
		http_status: 404,
		status_code: 104
	}

	# Used when requested data could not be returned
	REQUEST_ERROR = {
		http_status: 404,
		status_code: 105
	}

	# Used when object validation fails
	VALIDATION_ERROR = {
		http_status: 404,
		status_code: 106
	}
end

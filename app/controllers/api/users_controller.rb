class Api::UsersController < Api::ApiController
	before_filter :check_key

	def index
	end

	# Creates a User 
	def create
		user = User.new(user_params)
		
		# Save user, or return error message
		if !user.save
			error_msg(ErrorCodes::VALIDATION_ERROR, "Could not create user", user.errors)
			render_json
		else
			@response[:user] = user
			render_json(201)
		end

	rescue
		error_msg(ErrorCodes::ERROR, "Something went wrong")
		render_json
	end

	private

	#Kept secret so that admin functionality cannot be ingested
	def user_params
		params.require(:user).permit(:username, :name, :email, :role)
	end
end

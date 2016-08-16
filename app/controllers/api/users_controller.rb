class Api::UsersController < Api::ApiController
  before_filter -> { validate_rights 'manage_users' }, only: [:create, :update, :destroy]
  before_filter -> { validate_rights 'view_users' }, only: [:index]

  resource_description do
    short 'User manager'
  end

  api :GET, '/users', 'Returns all User objects'
  def index
    @response[:users] = User.all.order(:username)
    render_json
  end

  # Creates a User 
  api :POST, '/users', 'Creates a new User'
  example '{"user": {"username": "newUser", "name":"John Doe", "email": "testuser@test.com", "role":"ADMIN"}}'
  def create
    if params[:user] && params[:user][:password].blank?
      params[:user].delete(:password)
    end
    user = User.new(user_params)

    # Save user, or return error message
    if !user.save
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not create user", user.errors)
      render_json
    else
      @response[:user] = user
      render_json(201)
    end

  end

  # Updates a User
  api :PUT, '/users/:id', 'Updates a User object'
  example '{"user": {"username": "newUser", "name":"John Doe", "email": "testuser@test.com", "role":"ADMIN"}}'
  def update
    if params[:user] && params[:user][:password].blank?
      params[:user].delete(:password)
    end
    user = User.find(params[:id])
    
    if user.update_attributes(user_params)
      @response[:user] = user
    else
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not update user", user.errors)
    end

    render_json
  end

  # Renders a specific user object
  api :GET, '/users/:id', 'Returns a specific User object'
  example '{"user": {"username": "newUser", "name":"John Doe", "email": "testuser@test.com", "role":"ADMIN""}}'
  def show
    user = User.find_by_id(params[:id])

    if user
      @response[:user] = user
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not find user with id #{params[:id]}")
    end

    render_json
  end

  api :DELETE, '/users/:id', 'Deletes an existing User object from database.'
  def destroy
    user = User.find_by_id(params[:id])

    if user.delete
      @response[:user] = user
    else
      error_msg(ErrorCodes::OBJECT_ERROR, "Could not delete user with id #{params[:id]}")
    end

    render_json
  end

  private
  #Kept secret so that admin functionality cannot be ingested
  def user_params
    params.require(:user).permit(:username, :name, :email, :role, :password, :password_confirmation)
  end

end

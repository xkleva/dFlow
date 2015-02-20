class Api::TreenodesController < Api::ApiController
	before_filter :check_key

	def index
	end

	# Creates a Treenode 
	def create
   treenode = Treenode.new(treenode_params)
   
   # Save treenode, or return error message
   if !treenode.save
     error_msg(ErrorCodes::VALIDATION_ERROR, "Could not create treenode", treenode.errors)
     render_json
   else
     @response[:treenode] = treenode
     render_json(201)
   end

	end

	# Returns a Treenode
	def show
   if params[:id] == 'root'
     treenode = RootTreenode.new(name: "root")
   else
     treenode = Treenode.find_by_id(params[:id])
   end

   # If treenode does not exist, return error
   if treenode.nil?
     error_msg(ErrorCodes::OBJECT_ERROR, "Could not find Treenode with id #{params[:id]}")
     render_json
     return
   end

   @response[:treenode] = treenode.as_json({
     include_children: params[:show_children],
     include_jobs: params[:show_jobs],
     include_breadcrumb: params[:show_breadcrumb],
     include_breadcrumb_string: params[:show_breadcrumb_as_string]
   })

   render_json(200)
	end

  # Updates a treenode object
  def update
    treenode = Treenode.find(params[:id])

    if treenode.update_attributes(treenode_params)
      @response[:treenode] = treenode
    else
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not update treenode", treenode.errors)
    end

    render_json

  end

	private

	def treenode_params
   params.require(:treenode).permit(:name, :parent_id)
	end
end

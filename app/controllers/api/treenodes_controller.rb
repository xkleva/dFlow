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
		treenode = Treenode.find_by_id(params[:id])

		# If treenode does not exist, return error
		if treenode.nil?
			error_msg(ErrorCodes::OBJECT_ERROR, "Could not find Treenode with id #{params[:id]}")
			render_json
			return
		end

		@response[:treenode] = treenode.as_json

		# If flag 'show_children' is true, return all children in json response
		if params[:show_children]
			@response[:treenode][:children] = treenode.children
		end

		# If flag 'show_breadcrum' is true, return breadcrumb in json response
		if params[:show_breadcrumb]
			@response[:treenode][:breadcrumb] = treenode.breadcrumb
		end

		render_json(200)

	end

	private

	def treenode_params
		params.require(:treenode).permit(:name, :parent_id)
	end
end

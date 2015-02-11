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

	private

	def treenode_params
		params.require(:treenode).permit(:name, :parent_id)
	end
end

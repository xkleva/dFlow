class Api::TreenodesController < Api::ApiController

  before_filter -> { validate_rights 'manage_tree' }, only: [:create, :update, :destroy]

  resource_description do
    short 'Tree object manager - Tree structure objects and children management'
  end

  def index
  end

  # Creates a Treenode 
  api :POST, '/treenodes', 'Creates a new Treenode object'
  example '{"treenode": {"parent_id": 1, "name": "NewTreeNode"}}'.pretty_json
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
  api :GET, '/treenodes/:id', 'Returns a treenode object'
  param :show_children, :bool, desc: 'Includes child nodes when set to true'
  param :show_jobs, :bool, desc: 'Includes jobs under treeNode when set to true'
  param :page, :number, desc: 'Declares which page of job results should be retrieved (default: 1)'
  param :show_breadcrumb, :bool,  desc: 'Includes breadcrumb for treeNode when set to true'
  param :show_breadcrumb_as_string, :bool, desc: 'Includes a string representation of breadcrumb when set to true'
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
      job_pagination_page: params[:page],
      include_breadcrumb: params[:show_breadcrumb],
      include_breadcrumb_string: params[:show_breadcrumb_as_string]
    })

    render_json(200)
  end

  # Updates a treenode object
  api :PUT, '/treenodes/:id', 'Updates a TreeNode Object'
  example '{"treenode": {"parent_id": 1, "name": "NewTreeNodeName"}}'.pretty_json
  def update
    treenode = Treenode.find(params[:id])

    if treenode.update_attributes(treenode_params)
      @response[:treenode] = treenode
    else
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not update treenode", treenode.errors)
    end

    render_json

  end

  api :DELETE, '/treenodes/:id', 'Deletes a TreeNode Object'
  description 'Deletes a TreeNode object including all of its children TreeNode and Job objects. This operation cannot be undone'
  def destroy
    treenode = Treenode.find(params[:id])

    if treenode.delete
      @response[:treenode] = treenode
    else
      error_msg(ErrorCodes::VALIDATION_ERROR, "Could not delete treenode", treenode.errors)
    end

    render_json
  end

  private

  def treenode_params
    params.require(:treenode).permit(:name, :parent_id)
  end
end

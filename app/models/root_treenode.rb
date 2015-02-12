class RootTreenode < Treenode

  def children
    Treenode.where(parent_id: nil)
  end
  
end
class Treenode < ActiveRecord::Base
	belongs_to :parent, class_name: "TreeNode", foreign_key: "parent_id"
	validates :name, :presence => :true
end

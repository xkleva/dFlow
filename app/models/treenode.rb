class Treenode < ActiveRecord::Base
  belongs_to :parent, class_name: "Treenode", foreign_key: "parent_id"
  has_many :children, class_name: "Treenode", foreign_key: "parent_id"
  validates :name, :presence => :true
  validates_format_of :name, :with => /[a-zA-Z0-9]/
  validate :name_unique_for_parent

  validate :parent_id_exists, :if => :has_parent_id?

	# Vhecks if parent_id exists
  def has_parent_id?
    self.parent_id.to_s.is_i?
  end

  # Checks if parent exists based on current parent_id
  def parent_id_exists
    if Treenode.find_by_id(self.parent_id).nil?
      errors.add(:parent, "There is no node with id #{parent_id}")
    end
  end

  # Checks if name given is unique for current parent scope
  def name_unique_for_parent
    Treenode.where(parent_id: self.parent_id).each do |sibling|
      if self.name && sibling.name.casecmp(self.name) == 0
        errors.add(:name, "Name #{self.name} already exists under parent")
      end
    end
  end

  # Returns a list of objects containing id and name for parents until root is reached
  def breadcrumb
    breadcrumb = []
    current_parent = self.parent_id

    # Loop through entire parent structure
    while !current_parent.nil?
      tn = Treenode.find(current_parent)
      breadcrumb << {id: tn.id, name: tn.name}
      current_parent = tn.parent_id
    end

    # return breadcrumb starting from top parent
    return breadcrumb.reverse
  end

end

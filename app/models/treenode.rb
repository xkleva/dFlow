class Treenode < ActiveRecord::Base
  default_scope {where( :deleted_at => nil )}
  belongs_to :parent, class_name: "Treenode", foreign_key: "parent_id"
  has_many :children, class_name: "Treenode", foreign_key: "parent_id"
  has_many :jobs
  validates :name, :presence => :true
  validates_format_of :name, :with => /[a-zA-Z0-9]/
  validate :name_unique_for_parent

  validate :parent_id_exists, :if => :has_parent_id?
  validate :parent_id_change_destination

  after_update :handle_node_move

  def delete
    update_attribute(:deleted_at, Time.now)
    children.each {|child| child.delete}
    jobs.each {|job| job.delete}
  end

  # If node has been moved, update all jobs treenode_ids
  def handle_node_move
    if self.parent_id_changed?
      Job.all.each do |job|
        job.set_treenode_ids
        job.save(validate: false)
      end
    end
  end

  # Returns array of all parent ids
  def parent_ids
    parent_ids = []
    if has_parent_id?
      parent_ids += parent.parent_ids
    end
    parent_ids << id
    return parent_ids
  end

  def deleted?
    deleted_at.present?
  end

	# Checks if parent_id exists
  def has_parent_id?
    self.parent_id.to_s.is_i?
  end

  # Checks if parent exists based on current parent_id
  def parent_id_exists
    if Treenode.find_by_id(self.parent_id).nil?
      errors.add(:parent, "There is no node with id #{parent_id}")
    end
  end

  # Check that new parent_id is not self or subnode of self
  def parent_id_change_destination
    if parent_id == id && id
      errors.add(:parent, "Parent node cannot be itself")
    end
    if parent_id && is_subnode?(parent_id)
      errors.add(:parent, "Parent node cannot be below itself")
    end
  end

  # Check if id is subnode of this node
  def is_subnode?(child_id)
    children.each do |child| 
      return true if child_id == child.id || child.is_subnode?(child_id)
    end
    false
  end

  # Checks if name given is unique for current parent scope
  def name_unique_for_parent
    Treenode.where(parent_id: self.parent_id).each do |sibling|
      if self.name && sibling.name.casecmp(self.name) == 0 && self.id != sibling.id
        errors.add(:name, "Name #{self.name} already exists under parent")
      end
    end
  end

  # Returns a list of objects containing id and name for parents until root is reached
  def breadcrumb(options = {})
    return breadcrumb_as_string if options[:as_string]
    breadcrumb = []
    breadcrumb << {id: self.id, name: self.name } if options[:include_self] # Include self if flag is set
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

  # Returns a breadcrumb string based on breadcrumb array, including
  def breadcrumb_as_string
    @@breadcrumb ||= {}
    @@breadcrumb[self.id] ||= breadcrumb(include_self: true).map{|x| x[:name]}.join(" / ")
  end

  def as_json(options = {})
    base_json = super

    if options[:include_children]
      base_json[:children] = self.children
    end

    if options[:include_jobs]
      page = options[:job_pagination_page] || 1
      base_json.merge!(paginated_job_list(page))
    end

    if options[:include_breadcrumb]
      if options[:include_breadcrumb_string]
        base_json[:breadcrumb] = self.breadcrumb(as_string: true)
      else
        base_json[:breadcrumb] = self.breadcrumb
      end
    end

    base_json[:state_groups] = get_state_groups

    base_json[:jobs_count] = jobs.count

    base_json
  end

  def paginated_job_list(page)
    data = {}
    job_list = self.jobs
    job_count = job_list.count
    tmp = job_list.paginate(page: page)
    if tmp.current_page > tmp.total_pages
      job_list = job_list.paginate(page: 1)
    else
      job_list = tmp
    end
    job_list = job_list.order(:id).reverse_order
    data[:jobs] = job_list.as_json(list: true)
    pagination = {}
    pagination[:pages] = job_list.total_pages
    pagination[:page] = job_list.current_page
    pagination[:next] = job_list.next_page
    pagination[:previous] = job_list.previous_page
    pagination[:per_page] = job_list.per_page

    data[:meta] = {
      pagination: pagination,
      query: {total: job_count}
    }
    data
  end

  # Loads counts of job statuses for this node
  def get_state_groups
    jobs = Job.where("? = ANY (parent_ids)", id)
    state_groups = jobs.group('state').count
  end
end

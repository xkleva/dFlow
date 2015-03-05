if Rails.env == 'test'
### Assign your API-key here (must be aplpha-numerical)
Rails.application.config.api_key = 'test_key'

### USER ROLES DEFINITION
### Create a new role by adding another hash with a unique name of the role as well as a list of rights. Unassignable states that the role cannot be assigned to users.
### Available rights are: 'view_users', 'manage_users', 'view_tree', 'manage_tree', 'manage_tree_root'
Rails.application.config.user_roles = [
	{
    name: "ADMIN",
    rights: ['view_users', 'manage_users', 'view_tree', 'manage_tree', 'manage_tree_root', 'manage_jobs']
  },
  {
    name: "GUEST",
    unassignable: true,
    rights: ['view_tree']
  },
  {
    name: "OPERATOR",
    rights: ['view_tree', 'manage_tree', 'manage_jobs']
  },
  {
    name: "API_KEY",
    unassignable: true,
    rights: ['view_tree', 'manage_tree', 'manage_jobs']
  }
]

# Flags for using external authentication source
Rails.application.config.external_auth = true
Rails.application.config.external_auth_url = "https://login-server.example.com/auth"

# List of all available processes, the id is what identifies the process in the flow.
Rails.application.config.process_list = {
	"scan_job" => {
		id: "scan_job"
	},
	"rename_files" => {
		id: "rename_files"
	},
	"move_files" => {
		id: "move_files"
	},
	"copy_files" => {
		id: "copy_files"
	}
}

# List of available sources
Rails.application.config.sources = [
  {
    name: 'libris',
    label: 'Libris',
    class_name: 'Libris'
  },
  {
    name: 'other_source',
    label: 'Other Source',
    class_name: 'OtherSource'
  },
  {
    name: 'operakallan',
    label: 'Operakällan',
    class_name: 'UpperClass'
  }
]

# List of available events (used for job activity entries)
Rails.application.config.events = [
  {
    name: 'QUARANTINE'
  },
  {
    name: 'UNQUARANTINE'
  },
  {
    name: 'CREATE'
  },
  {
    name: 'UPDATE'
  },
  {
    name: 'CHANGE_STATUS'
  },
  {
    name: 'DELETE'
  },
  {
    name: 'STATUS'
  }
]

# List of available statuses
Rails.application.config.statuses = [
  {
    name: 'waiting_for_digitizing',
    next_status: 'digitizing'
  },
  {
    name: 'digitizing',
    next_status: 'post_processing'
  },
  {
    name: 'post_processing',
    next_status: 'quality_control'
  },
  {
    name: 'post_processing_user_input',
    next_status: 'post_processing'
  },
  {
    name: 'quality_control',
    next_status: 'waiting_for_mets_control'
  },
  {
    name: 'waiting_for_mets_control',
    next_status: 'mets_control'
  },
  {
    name: 'mets_control',
    next_status: 'done'
  },
  {
    name: 'done',
    next_status: nil
  }
]
end
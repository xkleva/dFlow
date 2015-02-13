module ModelHelper
	def config_init
		Rails.application.config.api_key = "test_key"

		Rails.application.config.user_roles = [
			{
				name: "ADMIN",
				rights: []
			},
			{
				name: "GUEST",
				unassignable: true,
				rights: []
			},
			{
				name: "OPERATOR",
				rights: []
			}
		]

		Rails.application.config.process_list = [
		{
			id: 1,
			code: "scan_job",
			manual: true
		},
		{
			id: 2,
			code: "rename_files",
			allowed_processes: 1
		},
		{
			id: 3,
			code: "move_files",
			allowed_processes: 1
		},
		{
			id: 4,
			code: "copy_files",
			allowed_processes: 1
		}
	]

		Rails.application.config.flow_parameters = [
			{
				id: 1,
				code: "deskew",
				type: "boolean"
			},
			{
				id: 2,
				code: "crop",
				type: "boolean"
			},
			{
				id: 3,
				code: "ocr",
				type: "boolean"
			},
			{
				id: 4,
				dependency: [{3 => true}],
				code: "ocr_flow",
				type: "string",
				values: ["littbank", "lasstod", "GUB"]
			}
		]

		Rails.application.config.sources = [
			{
				name: 'libris',
				label: 'Libris'
			},
			{
				name: 'other_source',
				label: 'Other Source'
			},
			{
				name: 'operakallan',
				label: 'Operakällan'
			}
		]
	end
end

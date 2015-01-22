# Defines the available processes
Rails.application.config.process_list = [
	{
		id: 1,
		name: "scan_job",
		type: "manual"
	},
	{
		id: 2,
		name: "rename_files",
		type: "automatic"
	},
	{
		id: 3,
		name: "move_files",
		type: "automatic"
	},
	{
		id: 4,
		name: "copy_files",
		type: "automatic"
	}
]

# Used to define flow templates
Rails.application.config.flow_templates = 
[
	{
		id: 1,
		name: "Standard-flow",
		params: [
			{
				id: 1,
				code: "disclaimer",
				type: :boolean,
				default: true
			},
			{
				id: 2,
				code: "ocr",
				type: :boolean,
				default: true
			},
			{
				id: 3,
				code: "ocr-flow",
				type: :string,
				default: "GUB-STANDARD",
				dependency: {dependency_id: 2, value: true}
			},
			{
				id: 4,
				code: "crop",
				type: :boolean,
				default: true
			}
		],
		flow_steps:
			[
				{
					id: 1,
					process_id: 1,
					goto_true: 2,
					#goto_false:
					#condition_method:
					#condition_operator:
					#condition_value:
					#params:
				},
				{
					id: 2,
					process_id: 2,
					goto_true: 3
					#goto_false:
					#condition_method:
					#condition_operator:
					#condition_value:
					#params:
				},
				{
					id: 3,
					process_id: 3
					#goto_true: 
					#goto_false:
					#condition_method:
					#condition_operator:
					#condition_value:
					#params:
				},
				{
					id: 4,
					#process_id:
					goto_true: 2,
					#goto_false
					condition_method: "1",
  					condition_operator: "eq",
  					condition_value: "true"
  					#params:
				}
			]
	}
]
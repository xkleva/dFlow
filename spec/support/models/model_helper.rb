# -*- coding: utf-8 -*-
module ModelHelper
  
  def config_init

    Rails.application.config.api_key = "test_key"
    Rails.application.config.external_auth = true
    Rails.application.config.external_auth_url = "https://login-server.example.com/auth"

    Rails.application.config.user_roles = [
      {
        name: "ADMIN",
        rights: ['manage_users', 'view_tree', 'manage_tree', 'view_users', 'manage_jobs']
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
        unassaignable: true,
        rights: ['view_tree', 'manage_tree', 'manage_users', 'view_users', 'manage_jobs']
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
        label: 'Libris',
        class_name: 'Libris'
      },
      {
        name: 'labras',
        label: 'Labras',
        class_name: 'Labras'
      },
      {
        name: 'other_source',
        label: 'Other Source',
        class_name: 'OtherSource'
      },
      {
        name: 'the_test_source',
        label: 'The Test Source',
        class_name: 'TestSource'
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
end

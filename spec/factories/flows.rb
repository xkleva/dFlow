FactoryGirl.define do
  sequence :flow_name do |n|
    "flow#{n}"
  end
  factory :flow do
    name {generate :flow_name}
    steps [
     {
            step: 10,
            process: "CONFIRMATION",
            description: "Väntar på digitalisering22g",
            goto_true: 20,
            goto_false: nil,
            params: {
                start: true,
                manual: true,
                msg: "Starta digitalisering"
            }
        },
        {
            step: 20,
            process: "COPY_FOLDER",
            description: "Kopiera mapp",
            condition: "1 > 2",
            goto_true: 30,
            goto_false: nil,
            params: {
                source_folder_path: "PROCESSING:/123",
                destination_folder_path: "PROCESSING:/111"
            }
        },    
        {
            step: 30,
            process: "COPY_FOLDER",
            description: "Kopiera mapp",
            condition: "1 > 2",
            goto_true: 40,
            goto_false: nil,
            params: {
                source_folder_path: "PROCESSING:/123",
                destination_folder_path: "PROCESSING:/111"
            }
        },    
        {
            step: 40,
            process: "COPY_FOLDER",
            description: "Kopiera mapp",
            condition: "1 > 2",
            goto_true: 50,
            goto_false: nil,
            params: {
                source_folder_path: "PROCESSING:/123",
                destination_folder_path: "PROCESSING:/111"
            }
        },
        {
            step: 50,
            process: "COPY_FOLDER",
            description: "Kopiera mapp",
            condition: "1 > 2",
            goto_true: nil,
            goto_false: nil,
            params: {
                source_folder_path: "PROCESSING:/123",
                destination_folder_path: "PROCESSING:/111"
            }
        }    
    ].to_json
  end
end

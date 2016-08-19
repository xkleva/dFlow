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
            description: "confirmation",
            goto_true: 30,
            params: {
                start: true,
                manual: true,
                msg: "Starta digitalisering"
            }
        },
        {
          step: 30,
          process: "CONFIRMATION",
          description: "confirmation",
          goto_true: 20,
          params: {
            manual: true
          }
        },
        {
            step: 20,
            process: "CONFIRMATION",
            description: "confirmation2",
            params: {
                manual: true,
                end: true,
                source_folder_path: "PROCESSING:/123",
                destination_folder_path: "PROCESSING:/111"
            }
        }    
    ].to_json
  end
end

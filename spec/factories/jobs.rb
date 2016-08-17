def metadata_json
  {
    "ordinal_1_key" => "\u00c5rg",
    "ordinal_1_value" => "1",
    "ordinal_2_key" => "Vol",
    "ordinal_2_value" => "2",
    "ordinal_3_key" => "N:r",
    "ordinal_3_value" => "3",
    "chron_1_key" => "\u00c5r",
    "chron_1_value" => "1978",
    "chron_2_key" => "M\u00e5n",
    "chron_2_value" => "September",
    "chron_3_key" => "Dag",
    "chron_3_value" => "6"
  }.to_json
end

FactoryGirl.define do

  sequence :job_name do |n|
    "job#{n}"
  end

  sequence :title do |n|
    "title#{n}"
  end

  sequence :author do |n|
    "author#{n}"
  end

  factory :job do
    name {generate :job_name}
    association :flow, factory: [:flow]
    association :treenode, factory: [:top_treenode]
    catalog_id '1'
    title {generate :title}
    author {generate :author}
    source 'libris'
    copyright false
    created_by 'TestUser'
    metadata "{}"
    current_flow_step 10
    state "ACTION"

    trait :deleted do
      deleted_at Time.now
    end

    trait :journal do
      metadata metadata_json
    end

    factory :deleted_job, traits: [:deleted]

    factory :journal_job, traits: [:journal]

  end

  factory :job_activity do |n|
    association :job, factory: [:job]
    username {generate :username}
    event 'CREATE'
    message 'Something was created'
  end

end

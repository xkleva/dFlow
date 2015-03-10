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
    catalog_id 1
    title {generate :title}
    author {generate :author}
    source 'libris'
    association :treenode, factory: [:top_treenode]
    status 'waiting_for_digitizing'
    copyright false
    created_by 'TestUser'
    metadata "{}"
  end

  factory :job_activity do |n|
    association :job, factory: [:job]
    username {generate :username}
    event 'CREATE'
    message 'Something was created'
  end

end
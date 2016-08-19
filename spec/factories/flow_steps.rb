FactoryGirl.define do
  sequence :step do |n|
    n*10+1
  end
  factory :flow_step do
    step {generate :step}
    association :job, factory: [:job]
    association :flow, factory: [:flow]
    process "CONFIRMATION"
    description "Test confirmation flow step"
    start_step

    trait :end_step do
      params "{\"manual\":true, \"end\":true}"
      goto_true nil
    end

    trait :start_step do
      params "{\"manual\":true, \"start\":true}"
      goto_true 30
    end
  end

end

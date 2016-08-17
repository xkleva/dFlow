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
    params "{\"manual\":true, \"end\":true}"
  end

end

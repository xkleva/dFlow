FactoryGirl.define do
  sequence :step do |n|
    n+1*10
  end
  factory :flow_step do
    step {generate :step}
    association :job, factory: [:job]
    process "CONFIRMATION"
    description "Test confirmation flow step"
    params "{\"manual\":true}"
  end

end

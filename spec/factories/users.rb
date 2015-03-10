FactoryGirl.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :username do |n|
    "user#{n}"
  end

  factory :user, class: User do
    username {generate :username}
    name "John Doe"
    guest
    email {generate :email}

    # Defines reusable traits which can be combined later into specific factories
    trait :guest do
      role "GUEST"
    end

    trait :admin do
      role "ADMIN"
    end

    trait :operator do
      role "OPERATOR"
    end

    trait :api_key do
      role "API_KEY"
    end

    trait :deleted do
      deleted_at Time.now
    end

    # Nested factories using traits, as class i already given on parent factory it is unnecessary here
    factory :guest_user, traits: [:guest]
    factory :admin_user, traits: [:admin]
    factory :operator_user, traits: [:operator]
    factory :api_key_user, traits: [:api_key]
    factory :deleted_user, traits: [:deleted]

    # Generate token for validation testing
    after(:create) do |user, evaluator|
      user.generate_token
    end
  end

  factory :access_token do |n|
    association :user, factory: :user
    token SecureRandom.hex
    token_expire Time.now+1.day
  end
end
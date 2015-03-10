FactoryGirl.define do

  sequence :name do |n|
    "treenode#{n}"
  end

  factory :treenode, class: Treenode do
    name {generate :name}
    topnode

    trait :topnode do
      parent nil
    end

    trait :deleted do
      deleted_at Time.now
    end

    factory :top_treenode, traits: [:topnode]
    factory :deleted_treenode, traits: [:deleted]
  end

  factory :child_treenode, parent: :treenode do
    association :parent, factory: [:top_treenode]
  end

  factory :grandchild_treenode, parent: :treenode do
    association :parent, factory: [:child_treenode]
  end
end
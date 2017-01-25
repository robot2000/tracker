FactoryGirl.define do
  factory :day do
    date Date.today

    initialize_with { new(attributes) }
  end
end

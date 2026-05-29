FactoryBot.define do
  factory :transfer do
    user_id { 1 }
    amount { 50_000 }
    sequence(:idempotency_key) { |n| "key-#{n}" }
    status { :pending }
  end
end

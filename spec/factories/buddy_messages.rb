FactoryBot.define do
  factory :buddy_message do
    association :post
    association :user
    role { :user }
    content { "テストメッセージ" }
  end
end

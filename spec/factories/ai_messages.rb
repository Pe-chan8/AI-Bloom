FactoryBot.define do
  factory :ai_message do
    association :user
    association :post
    association :buddy
    kind { :reply }
    content { "AIからのテストメッセージ" }
  end
end

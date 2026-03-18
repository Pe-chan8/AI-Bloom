FactoryBot.define do
  factory :buddy do
    sequence(:code) { |n| "buddy_#{n}" }
    name { "ニル" }
    persona_prompt { "やさしく寄り添って話してください" }
    is_active { true }
  end
end

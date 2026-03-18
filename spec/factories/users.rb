FactoryBot.define do
  factory :user do
    nickname { "テストユーザー" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    after(:build) do |user|
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end
end

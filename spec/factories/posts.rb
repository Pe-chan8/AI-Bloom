FactoryBot.define do
  factory :post do
    association :user
    body { "今日はがんばった" }
    posted_at { Time.zone.now }
    title { "テスト投稿" }

    category do
      if Post.respond_to?(:categories) && Post.categories.is_a?(Hash) && Post.categories.any?
        Post.categories.keys.first
      else
        "general"
      end
    end
  end
end

namespace :data do
  desc "Backfill posts.category from tags_text"
  task backfill_post_category: :environment do
    mapping = {
      "仕事" => "work",
      "恋愛" => "love",
      "家庭" => "family",
      "学習" => "study",
      "その他" => "other",
    }

    updated = 0

    User.find_each do |u|
      u.posts.where(category: [nil, ""]).find_each do |p|
        t = p.tags_text.to_s
        next if t.blank?

        new_cat = mapping.find { |jp, _| t.include?(jp) }&.last
        next unless new_cat

        p.update!(category: new_cat)
        updated += 1
      end
    end

    puts "done! updated=#{updated}"
  end
end

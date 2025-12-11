class EnsureBuddyNicknamesAndKansaiBuddy < ActiveRecord::Migration[8.1]
  class Buddy < ActiveRecord::Base
    self.table_name = "buddies"
  end

  def up
    Buddy.find_by(code: "normal")&.update!(name: "ニル")
    Buddy.find_by(code: "amiable")&.update!(name: "ルナ")
    Buddy.find_by(code: "analytical")&.update!(name: "キエル")
    Buddy.find_by(code: "driving")&.update!(name: "ヴァル")
    Buddy.find_by(code: "expressive")&.update!(name: "エルフィ")

    kansai = Buddy.find_or_initialize_by(code: "kansai_friend")
    kansai.name = "レオ"
    kansai.description = "親しみやすくてツッコミもしてくれる、神戸の友達ペンギン。明るく励ましながら、気持ちに寄り添うタイプです。"
    kansai.tone_hint = "親しみやすいメスの神戸弁。やさしく共感しつつ、軽くツッコミを入れながら前向きな一歩を勧める。"
    kansai.is_active = true if kansai.respond_to?(:is_active)
    kansai.save!
  end
end

# frozen_string_literal: true

class TopMessageService
  def initialize(user:)
    @user = user
  end

  def call
    return default_message unless user

    if streak_days >= 7
      "すごいね。#{streak_days}日連続で記録できてるよ。少しずつ、ちゃんと積み上がってる。"
    elsif streak_days >= 3
      "いい感じ。#{streak_days}日連続で続けられてるよ。無理なくこのペースでいこう。"
    elsif mood_trend == :up
      "最近ちょっと気分が上向いてきてるみたい。小さな変化も、ちゃんと前進だよ。"
    elsif mood_trend == :down
      "最近は少しおつかれ気味かも。今日は無理せず、気持ちをここに置いていこう。"
    else
      "今日の気持ちも、ここにそっと置いていこう。言葉にするだけでも十分えらいよ。"
    end
  end

  private

  attr_reader :user

  def default_message
    "今日の気持ちも、ここにそっと置いていこう。言葉にするだけでも十分えらいよ。"
  end

  def posts
    @posts ||= user.posts.order(posted_at: :desc, created_at: :desc)
  end

  def streak_days
    dates = posts.where.not(posted_at: nil).pluck(:posted_at).map(&:to_date).uniq.sort.reverse
    return 0 if dates.empty?

    streak = 1
    dates.each_cons(2) do |current_date, next_date|
      break unless current_date - 1 == next_date

      streak += 1
    end

    streak
  end

  def mood_trend
    recent_moods = posts.where.not(mood: nil).order(posted_at: :asc, created_at: :asc).last(3).map(&:mood_before_type_cast)
    return :neutral if recent_moods.size < 3

    if recent_moods.last > recent_moods.first
      :up
    elsif recent_moods.last < recent_moods.first
      :down
    else
      :neutral
    end
  end
end

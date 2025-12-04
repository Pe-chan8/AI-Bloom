module Ai
  class RateLimiter
    DAILY_LIMIT = 20        # 1日の上限回数（あとで調整する可能性あり）
    WINDOW      = 1.day

    class LimitExceeded < StandardError; end

    def initialize(user)
      @user = user
    end

    # kind: :reply / :daily など用途ごとに分けられるようにしておく
    def check_and_count!(kind:)
      key = cache_key(kind)

      # Rails.cache のカウンタを1増やしつつ、期限を1日に設定
      count = Rails.cache.increment(key, 1, expires_in: WINDOW)

      count ||= 1

      raise LimitExceeded, "AI call limit exceeded" if count > DAILY_LIMIT

      count
    end

    private

    def cache_key(kind)
      date = Time.current.strftime("%Y%m%d")
      "ai_rate:user:#{@user.id}:#{kind}:#{date}"
    end
  end
end

Sentry.init do |config|
  # DSN は環境変数から取得（未設定なら Sentry 無効）
  config.dsn = ENV["SENTRY_DSN"]

  # どの環境で Sentry を有効にするか
  config.enabled_environments = %w[production]

  # Rails.logger や HTTP リクエストをパンくずに残す
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # パフォーマンス計測（APM）のサンプリング率
  # MVP では低め（0.0 〜 0.1 程度）
  config.traces_sample_rate = 0.0

  # プロファイリングはとりあえず OFF
  config.profiles_sample_rate = 0.0

  # リリース名をつけたい場合（任意）
  # config.release = ENV["SENTRY_RELEASE"]
end

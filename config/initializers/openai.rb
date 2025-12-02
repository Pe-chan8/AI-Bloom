OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY", nil)

  # 将来 API ベース URL を変えるとき用のコメント
  # config.request_timeout = 120
end

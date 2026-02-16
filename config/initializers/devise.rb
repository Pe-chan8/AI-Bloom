# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "no-reply@ai-bloom.example")

  require "devise/orm/active_record"

  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  config.skip_session_storage = [ :http_auth ]

  config.stretches = Rails.env.test? ? 1 : 12

  config.reconfirmable = true

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.sign_out_via = :delete

  # -------------------------------------------------------
  # OmniAuth (Google)
  # ※ 開発/CIでENV未設定でも generator 等が動くようにガード
  # -------------------------------------------------------
  google_client_id     = ENV["GOOGLE_CLIENT_ID"]
  google_client_secret = ENV["GOOGLE_CLIENT_SECRET"]

  if google_client_id.present? && google_client_secret.present?
    config.omniauth :google_oauth2,
                    google_client_id,
                    google_client_secret,
                    {
                      prompt: "select_account",
                      access_type: "online"
                    }
  else
    Rails.logger.info("[Devise] GOOGLE_CLIENT_ID/SECRET is not set. Google login is disabled.")
  end

  # Hotwire/Turbo
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end

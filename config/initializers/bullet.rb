# frozen_string_literal: true

return unless Rails.env.development?

Rails.application.config.after_initialize do
  Bullet.enable = true

  Bullet.n_plus_one_query_enable = true
  Bullet.unused_eager_loading_enable = true
  Bullet.counter_cache_enable = true

  Bullet.alert = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.bullet_logger = true
  Bullet.add_footer = true

  Bullet.skip_html_injection = false
  Bullet.skip_http_headers = false
end

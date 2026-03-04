# frozen_string_literal: true

if Rails.env.development?
  require "bullet"

  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true

      Bullet.alert = true          # ブラウザalert
      Bullet.console = true        # ブラウザconsole
      Bullet.rails_logger = true   # Railsログ (development.log)
      Bullet.bullet_logger = true  # log/bullet.log

      Bullet.add_footer = true

      Bullet.n_plus_one_query_enable = true
      Bullet.unused_eager_loading_enable = true
      Bullet.counter_cache_enable = true
    end
  end

  Rails.application.config.middleware.use Bullet::Rack
end

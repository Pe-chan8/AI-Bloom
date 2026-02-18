require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module AiBloom
  class Application < Rails::Application
    config.load_defaults 8.1

    config.assets.paths << Rails.root.join("app/javascript")

    config.i18n.default_locale = :ja
    config.i18n.available_locales = %i[ja en]

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :utc

    config.action_mailer.default_options = {
      from: ENV.fetch("MAILER_FROM", "noreply@ai-bloom.jp")
    }
  end
end

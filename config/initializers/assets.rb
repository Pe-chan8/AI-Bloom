Rails.application.config.assets.paths << Rails.root.join("app/assets/images")
Rails.application.config.assets.paths << Rails.root.join("app/javascript")
Rails.application.config.assets.paths << Rails.root.join("app/javascript/controllers")

Rails.application.config.assets.precompile += %w[
  controllers/hamburger_menu_controller.js
]

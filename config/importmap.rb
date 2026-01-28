pin "application", to: "application.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true

pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# コントローラー（明示的に pin）
pin "controllers/application", to: "controllers/application.js", preload: true
pin "controllers/index", to: "controllers/index.js", preload: true
pin "controllers/post_modal_controller", to: "controllers/post_modal_controller.js"
pin "controllers/ga_controller", to: "controllers/ga_controller.js"
pin "controllers/ga_event_controller", to: "controllers/ga_event_controller.js"

# controllers エイリアス
pin "controllers", to: "controllers/index.js"

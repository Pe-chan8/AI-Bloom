pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

pin "controllers", to: "controllers/index.js", preload: true

pin "controllers/application", to: "controllers/application.js", preload: true
pin "controllers/ga_controller", to: "controllers/ga_controller.js"
pin "controllers/ga_event_controller", to: "controllers/ga_event_controller.js"
pin "controllers/hamburger_menu_controller", to: "controllers/hamburger_menu_controller.js"
pin "controllers/hello_controller", to: "controllers/hello_controller.js"
pin "controllers/help_tip_controller", to: "controllers/help_tip_controller.js"
pin "controllers/meta_collapse_controller", to: "controllers/meta_collapse_controller.js"

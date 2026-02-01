pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

pin "controllers", to: "controllers/index.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin "controllers/hamburger_menu_controller", to: "controllers/hamburger_menu_controller.js"

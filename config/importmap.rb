# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
# Stimulus 系は一旦使わないのでコメントアウトしてもOK
# pin "@hotwired/stimulus", to: "stimulus.min.js"
# pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
# pin_all_from "app/javascript/controllers", under: "controllers"

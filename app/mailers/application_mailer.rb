class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "AI-bloom <no-reply@localhost>")
  layout "mailer"
end

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_EMAIL", "noreply@fmug.local")
  layout "mailer"
end

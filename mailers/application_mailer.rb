class ApplicationMailer < ActionMailer::Base
  helper WebAppRoute
  default from: "hi@#{ENV['ROOT_DOMAIN']}"
  layout 'mailer'
end

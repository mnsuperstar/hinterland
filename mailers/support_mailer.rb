class SupportMailer < ApplicationMailer
  def incoming_message(message, receivers)
    @message = message
    mail(to: receivers, subject: "You've received a new message on Hinterlands!")
  end
end

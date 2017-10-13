class SendgridEventJob < ApplicationJob
  queue_as :default

  def perform(sendgrid_event)
    sendgrid_event.recipients.each do |recipient|
      UserMailer.forward_sendgrid_event(recipient.email, sendgrid_event).deliver_later
    end
  end
end

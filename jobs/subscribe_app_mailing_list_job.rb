class SubscribeAppMailingListJob < ApplicationJob
  queue_as :default

  def perform(newsletter)
    if ENV['MAILCHIMP_NEWSLETTER_LIST_ID'].present?
      service = EmailService.new
      service.subscribe ENV['MAILCHIMP_NEWSLETTER_LIST_ID'], {email: newsletter.email}
    end
  end
end

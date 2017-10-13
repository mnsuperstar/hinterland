class SubscribeUserToMailingListJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    if ENV['MAILCHIMP_LIST_ID'].present?
      service = EmailService.new
      service.subscribe(ENV['MAILCHIMP_LIST_ID'],
                        { email: user.email },
                        { 'FNAME' => user.first_name, 'LNAME' => user.last_name }
                       )
    end
  end
end

class PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(user, message, options = {})
    user.try(:devices).try(:send_message, message, options)
  end
end

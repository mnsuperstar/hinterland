class NotifyNewUserJob < PushNotificationJob
  rescue_from(ActiveJob::DeserializationError) do
    # ignore when user no longer exists
  end

  def perform(user)
    return unless user.adventurer?
    super(
      user,
      I18n.t(:adventurer_welcome, scope: %i(notification user)),
      extra: { type: 'adventurer.welcome' }
    ) if user.push_notification
  end
end

class NotifyGuideAdventureJob < PushNotificationJob
  rescue_from(ActiveJob::DeserializationError) do
    # ignore when user no longer exists
  end

  def perform(user)
    return if !user.guide? || user.adventures.any?
    super(
      user,
      I18n.t(:on_boarding_reminder, scope: %i(notification user)),
      extra: { type: 'guide.on_boarding_reminder' }
    ) if user.push_notification
  end
end

class NotifyUpcomingAdventureJob < PushNotificationJob
  def perform(booking)
    users = [booking.adventurer, booking.guide]
    users.each do |user|
      super(
        user,
        I18n.t(:upcoming_adventure,
                scope: %i(notification booking),
                adventure: booking.adventure.title
              ),
        extra: { type: 'booking.reminder', booking_uid: booking.uid }
      ) if user.push_notification
    end
  end
end

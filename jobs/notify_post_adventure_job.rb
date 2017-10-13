class NotifyPostAdventureJob < PushNotificationJob
  rescue_from(ActiveJob::DeserializationError) do
    # ignore when booking no longer exists
  end

  def perform(booking, type = nil)
    if type && booking.is_reviewable
      case type
      when 'push_notif'
        super(
          booking.adventurer,
          I18n.t(:post_adventure,
                   scope: %i(notification booking),
                   adventure: booking.adventure.title
                ),
          extra: { type: 'booking.post_adventure', booking_uid: booking.uid }
        ) if booking.adventurer.push_notification
      when 'email'
        UserMailer.notify_leave_review(booking).deliver_now
      when 'reminder_email'
        UserMailer.notify_leave_review_reminder(booking).deliver_now
      end
    end
  end
end

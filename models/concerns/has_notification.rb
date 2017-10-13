module HasNotification
  extend ActiveSupport::Concern
  include WebAppRoute

  included do
    after_commit :send_guide_notification, :send_adventurer_notification, on: [:create]
    after_update :send_booking_notification_status
    after_update :schedule_reminder_notification, :schedule_post_adventure_notification,
                 if: proc { |booking| booking.status_changed? && booking.accepted? }
    after_save :send_itinerary_recipients, if: -> (booking) { booking.status_changed? && booking.accepted? }
  end

  private

  def send_adventurer_notification
    AdventurerPostBookingCreationJob.set(wait_until: 2.hours.from_now).perform_later(id)
  end

  def send_guide_notification
    if guide
      if guide.try(:email_notification)
        UserMailer.notify_new_booking_created(guide, self)
                  .deliver_later
      end
      if guide.try(:push_notification)
        PushNotificationJob.perform_later(guide,
                                          I18n.t(:guide_booking,
                                            scope: %i(notification booking),
                                            adventurer: adventurer.first_name, adventure: adventure.title
                                          ),
                                          extra: { type: 'booking.request', booking_uid: uid })
      end

      GuidePostBookingCreationJob.set(wait_until: 2.hours.from_now).perform_later(id, 'push_notif')
      GuidePostBookingCreationJob.set(wait_until: 8.hours.from_now).perform_later(id, 'email')
    end
  end

  def send_booking_notification_status
    return if !status_changed? || pending?

    if rejected?
      UserMailer.notify_rejected_booking(adventurer, self)
                .deliver_later if adventurer.email_notification
      UserMailer.notify_rejected_booking(guide, self)
                .deliver_later if guide.try(:email_notification)
    elsif accepted?
      UserMailer.notify_itinerary_recipients(adventurer.email, self).deliver_later
      UserMailer.notify_accepted_booking(adventurer, self)
                .deliver_later if adventurer.email_notification
    elsif canceled?
      UserMailer.notify_canceled_booking(adventurer, self)
                .deliver_later if adventurer.email_notification
      UserMailer.notify_canceled_booking(guide, self)
                .deliver_later if guide.try(:email_notification)
    end

    if adventurer.push_notification
      PushNotificationJob.perform_later(adventurer,
                                        I18n.t(status,
                                          scope: %i(notification booking status_changed),
                                          guide: (guide.try(:first_name).presence || "Guide"),
                                          adventure: adventure.title
                                        ),
                                        extra: { type: "booking.#{status}", booking_uid: uid })
    end
  end

  def schedule_reminder_notification
    NotifyUpcomingAdventureJob
      .set(wait_until: 1.day.until(start_on).to_datetime.change(hour: created_at.hour))
      .perform_later(self)
  end

  def schedule_post_adventure_notification
    NotifyPostAdventureJob
      .set(wait_until: 24.hours.since(end_on).in_time_zone("EST").change(hour: created_at.hour))
      .perform_later(self, 'push_notif')
    NotifyPostAdventureJob
      .set(wait_until: end_on.in_time_zone("EST").change(hour: 20))
      .perform_later(self, 'email')
    NotifyPostAdventureJob
      .set(wait_until: 24.hours.since(end_on).in_time_zone("EST").change(hour: 20))
      .perform_later(self, 'reminder_email')
  end

  def send_itinerary_recipients
    if itinerary_recipients.present?
      UserMailer.notify_itinerary_recipients(itinerary_recipients, self)
                .deliver_later
    end
  end
end

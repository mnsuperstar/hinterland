class GuidePostBookingCreationJob < ApplicationJob
  queue_as :default

  def perform(booking_id, type)
    booking = Booking.find_by(id: booking_id)
    return if booking.nil? || !booking.pending?
    if type == 'push_notif'
      adventurer = booking.adventurer
      guide = booking.guide
      guide.try(:devices)
           .try(:send_message, I18n.t(:guide_post_booking,
                                      scope: %i(notification booking),
                                      adventurer_name: adventurer.short_name
                                     ),
                extra: { type: 'booking.post_request', booking_uid: booking.uid })
    else
      UserMailer.notify_post_booking_creation(booking).deliver_now
    end
  end
end

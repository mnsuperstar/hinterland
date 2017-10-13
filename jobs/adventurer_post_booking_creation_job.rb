class AdventurerPostBookingCreationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return if booking.nil? || !booking.pending?
    adventurer = booking.adventurer
    adventurer.try(:devices)
         .try(:send_message, I18n.t(:adventurer_post_booking,
                                    scope: %i(notification booking)
                                   ),
              extra: { type: 'booking.post_request', booking_uid: booking.uid })
    UserMailer.notify_post_booking_creation_for_adventurer(booking).deliver_now
  end
end

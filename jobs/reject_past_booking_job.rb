class RejectPastBookingJob < ApplicationJob
  queue_as :default

  def perform
    Booking.pending.past.find_each do |booking|
      booking.status = 'rejected'
      booking.save!(validate: false)
    end
  end
end

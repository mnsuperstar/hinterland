class RejectExpiredBookingsJob < ApplicationJob
  queue_as :default

  def perform
    Booking.expired do |booking|
      booking.rejected!
    end
  end
end

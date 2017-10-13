class AdventureReminderJob < ApplicationJob
  queue_as :default

  def perform
    Booking.due_by_tomorrow.find_each do |booking|
      UserMailer.adventure_reminder(booking).deliver_now
    end
  end
end

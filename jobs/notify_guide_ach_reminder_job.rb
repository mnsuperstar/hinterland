class NotifyGuideAchReminderJob < ApplicationJob
  queue_as :default

  def perform
    User.guides.need_ach_reminder do |guide|
      UserMailer.send_guide_ach(guide).deliver_now
      guide.update_column(:reminded_at, DateTime.now)
    end
  end
end

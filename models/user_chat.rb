# == Schema Information
#
# Table name: user_chats
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  chat_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  read_at     :datetime
#  notified_at :datetime
#

class UserChat < ApplicationRecord
  belongs_to :user
  belongs_to :chat

  def self.missed
    where('notified_at < ? OR notified_at IS NULL', AppSetting['chat.missed_time'].ago)
  end

  def read!
    update_columns(read_at: Time.zone.now, notified_at: Time.zone.now)
  end

  def notify!
  	if user.email_notification
      UserMailer.notify_missed_chat_messages(user, chat, notified_at)
                .deliver_now
    end
  	update_column(:notified_at, Time.zone.now)
  end
end

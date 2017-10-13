# == Schema Information
#
# Table name: notification_settings
#
#  id                 :integer          not null, primary key
#  push_notification  :boolean          default(TRUE)
#  email_notification :boolean          default(TRUE)
#  chat_notification  :boolean          default(TRUE)
#  user_id            :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class NotificationSetting < ApplicationRecord
  belongs_to :user

  include HasApi

  def self.api_attributes
    %i(push_notification email_notification chat_notification)
  end
end

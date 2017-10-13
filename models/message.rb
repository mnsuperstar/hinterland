# == Schema Information
#
# Table name: messages
#
#  id            :integer          not null, primary key
#  chat_id       :integer
#  user_id       :integer
#  content       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  uid           :string
#  image_content :string
#  company_id    :integer
#

class Message < ApplicationRecord
  include HasApi
  include HasUid
  include HasCompany

  belongs_to :chat, touch: true
  belongs_to :user

  scope :before, ->(time) { where("created_at < ? ", Time.at(time.to_i))}
  scope :after, ->(time) {where("created_at > ? ", Time.at(time.to_i))}
  scope :ordered, -> { order(created_at: :desc, id: :desc) }
  scope :asc_ordered, -> { order(created_at: :asc, id: :asc) }

  mount_uploader :image_content, ImageUploader

  delegate :uid, to: :chat, prefix: true

  validates :content, :user, :chat, presence: true

  validate :no_paypal_content
  validate :blocked_by_participants

  after_commit :update_chat_initiator, on: [:create]
  after_commit :broadcast_create_event, :send_message_notification, on: [:create]
  after_commit :update_chat_responded_at, on: [:create]
  before_destroy :ensure_removable

  def self.api_attributes
    %i(uid content image_content chat_uid user created_at)
  end

  def recipients
    chat
      .users
      .joins("LEFT JOIN blocked_users ON blocked_users.blocker_id = users.id AND blocked_users.blockee_id = #{user.id}")
      .where('blocked_users.id IS NULL')
  end

  def recipients_except_sender
    recipients.where.not(users: { id: user.id })
  end

  private

  def update_chat_initiator
    chat.update_attributes(initiator: user) if chat.initiator.nil?
  end

  def broadcast_create_event
    ChatBroadcastJob.perform_later('send_message', self) if user.chat_notification
  end

  def send_message_notification
    self.recipients_except_sender.includes(:notification_setting).each do |user|
      PushNotificationJob.perform_later(
        user,
        I18n.t(:new_message,
               scope: %i(notification message),
               user: user.first_name
              ),
        extra: { type: 'message.create', chat_uid: chat_uid },
        badge: 1
      ) if user.push_notification
    end
    support_receivers = recipients_except_sender.supports.pluck(:email)
    SupportMailer.incoming_message(self, support_receivers).deliver_later if support_receivers.present?
  end

  # This blocks anyone posting a link from paypal in chat
  def no_paypal_content
    errors.add_to_base("Please, no thirdparty websites.") if content =~ /paypal/i
  end

  def blocked_by_participants
    errors.add(:base, :blocked) if chat.users.length == 2 && BlockedUser.on_users(*chat.users).exists?
  end

  def update_chat_responded_at
    if chat.responded_at.nil? && chat.first_message.user_id != user_id
      chat.responded!(created_at)
    end
  end

  def ensure_removable
    unless current_user == user
      errors.add(:base, :not_removable)
      raise ActiveRecord::Rollback
    end
  end
end

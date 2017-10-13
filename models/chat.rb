# == Schema Information
#
# Table name: chats
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  uid          :string
#  responded_at :datetime
#  initiator_id :integer
#  company_id   :integer
#

class Chat < ApplicationRecord
  MINIMUM_USERS = 2
  has_many :messages, dependent: :destroy

  has_many :user_chats, -> { order(:created_at, :id) }, dependent: :destroy
  has_many :users, through: :user_chats

  belongs_to :initiator, class_name: 'User'

  include HasUid
  include HasApi
  include CalculatableResponse
  include HasCompany

  validate :minimum_users_count
  validate :blocked_by_participants

  scope :with_messages, -> { joins(:messages).distinct }
  scope :responded_quickly, -> { where("responded_at IS NOT NULL AND responded_at <= chats.created_at + '1 day'::interval") }
  scope :not_initiated_by, -> (user) { where.not(initiator: user) }
  scope :message_unread_check, -> { joins('LEFT JOIN messages m_u_check ON m_u_check.chat_id = chats.id AND m_u_check.created_at > user_chats.read_at AND m_u_check.user_id != user_chats.user_id') }
  scope :with_has_unread_messages, -> { message_unread_check.select('chats.*, COALESCE(m_u_check.id, 0) != 0 AS has_unread_messages') }
  scope :with_unread_messages, -> { message_unread_check.where('m_u_check.id IS NOT NULL') }

  def self.api_attributes
    %i(uid users_api_attribute last_message has_unread_messages created_at)
  end

  def self.index_api_attributes
    %i(uid users last_message has_unread_messages created_at)
  end

  def self.ws_api_attributes
    api_attributes - %i(has_unread_messages)
  end

  def self.find_for_user_uids uids
    having('COUNT(users.uid) = ?', uids.length)
      .where(users: { uid: uids } )
      .group('chats.id').joins(:users)
      .detect{|c| c.users.count == uids.length}
  end

  def first_message
    messages.ordered.last
  end

  def last_message
    messages.ordered.first
  end

  def responded!(time = Time.zone.now)
    update_column :responded_at, time
  end

  def has_unread_messages
    self[:has_unread_messages]
  end

  def read_at
    current_user ? current_user.user_chats.where(chat: self).first.try(:read_at) : nil
  end

  def users_api_attribute
    users.with_phone_number.group('user_chats.id, users.id').to_api_data(:chat_nested)
  end

  private

  def minimum_users_count
    errors.add(:users, :not_enough, minimum: MINIMUM_USERS) if users.uniq.length < MINIMUM_USERS
  end

  def blocked_by_participants
    errors.add(:base, :blocked) if users.length == 2 && BlockedUser.on_users(*users).exists?
  end
end

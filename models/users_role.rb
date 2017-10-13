# == Schema Information
#
# Table name: users_roles
#
#  user_id                :integer
#  role_id                :integer
#  is_featured            :boolean          default(FALSE)
#  id                     :integer          not null, primary key
#  reviews_count          :integer          default(0), not null
#  reviews_average_rating :decimal(2, 1)
#  is_verified            :boolean          default(FALSE), not null
#  is_primary             :boolean          default(FALSE), not null
#

class UsersRole < ApplicationRecord
  include Reviewable
  include SlackNotifier

  slack_notify_on :create,
                  action_text: {
                    create: "signed up as"
                  },
                  object_name: :role_name,
                  actor: :user

  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id }
  scope :not_primary, -> {where(is_primary: false)}
  scope :primary, -> {where(is_primary: true)}

  delegate :uid, to: :user, prefix: false
  delegate :name, to: :role, prefix: true

  after_save :update_others_false,
    if: proc{ |ur| ur.is_primary && ur.is_primary_changed? }
  after_commit :send_partner_application_email, on: [:create]

  def self.find_by_user_uid_and_role_name user_uid, role_name
    joins(:user, :role).find_by(users: { uid: user_uid }, roles: { name: role_name })
  end

  def self.find_guide
    UsersRole.joins(:user, :role).where(roles: { name: 'guide' })
  end

  def self.find_adventurer
    UsersRole.joins(:user, :role).where(roles: { name: 'adventurer' })
  end

  def verify!
    update! is_verified: true
  end

  def unverify!
    update! is_verified: false
  end

  private

  def update_others_false
    user.users_roles.where(is_primary: true).where.not(id: id).update_all(is_primary: false)
  end

  def send_partner_application_email
    UserMailer.notify_partner_application_email_received(user).deliver_later if user && role.try(:name) == 'guide' && !is_verified
  end
end

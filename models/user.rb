# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  uid                    :string           not null
#  auth_token             :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  first_name             :string
#  last_name              :string
#  bio                    :text
#  is_using_oauth         :boolean
#  latitude               :decimal(9, 6)
#  longitude              :decimal(9, 6)
#  gender                 :integer          default("not_specified"), not null
#  birthdate              :date
#  location               :string
#  profile_photo          :string
#  background_photo       :string
#  past_guides_count      :integer          default("0")
#  phone_number           :string
#  stripe_customer_id     :string
#  email_alias            :string
#  response_rate          :float            default(100.0)
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  credit_amount_cents    :integer          default(0), not null
#  credit_amount_currency :string           default("USD"), not null
#  slug                   :string
#  adventures_count       :integer
#  reminded_at            :datetime
#  company_id             :integer
#

class User < ApplicationRecord
  # rolify
  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
         :recoverable, :rememberable, :trackable,
         :omniauthable, omniauth_providers: [:facebook]

  include HasUid
  include HasApi
  include HasRole
  include AsAdventurer
  include AsGuide
  include HasOmniauth
  include HasPhoneNumber
  include HasStripeCustomer
  include Blockable
  include FriendlyId
  include HasUserAgent
  include HasCreditHistory
  include HasCompany

  friendly_id :slug_candidates, use: [:slugged, :finders]
  mount_uploader :profile_photo, ProfileUploader
  mount_uploader :background_photo, ProfileBackgroundUploader

  before_create :ensure_auth_token, :ensure_email_alias, :ensure_notification_setting
  after_update :notify_email_updated,
    if: proc { |user| user.email_changed? }
  after_commit :add_to_mixpanel, :add_mailchimp_subscriber, on: [:create]
  before_update :update_mixpanel

  has_many :user_activities, dependent: :destroy
  has_many :activities, through: :user_activities

  has_many :reviews, foreign_key: 'reviewer_id', dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :user_chats, dependent: :destroy
  has_many :chats, through: :user_chats
  has_many :initiated_chats, foreign_key: 'initiator_id', class_name: 'Chat', dependent: :nullify
  has_many :cards, as: :owner, dependent: :destroy
  has_one :notification_setting, dependent: :destroy
  has_many :adventures_users, dependent: :destroy
  has_many :favorite_adventures, -> { order('adventures_users.created_at DESC') },
                                through: :adventures_users, source: :adventure

  accepts_nested_attributes_for :certifications
  accepts_nested_attributes_for :notification_setting

  validates_presence_of   :email, if: :email_required?
  validates_uniqueness_of :email, scope: :company_id, allow_blank: true, if: :email_changed?
  validates_format_of     :email, with: Devise.email_regexp, allow_blank: true, if: :email_changed?

  validates_presence_of     :password, if: :password_required?
  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :password, within: Devise.password_length, allow_blank: true

  validates :first_name, presence: true
  validates :first_name, :last_name, length: { maximum: 50 }
  validates :bio, length: { maximum: 1500 }

  delegate :push_notification, :email_notification, :chat_notification,
           to: :notification_setting, allow_nil: true

  alias_attribute :email_api_attribute_alias, :email_alias

  enum gender: %w(not_specified male female other)
  def self.api_attributes
    %i(uid email_api_attribute_alias first_name short_name shortened_last_name user_type
       gender birthdate bio location
       profile_photo background_photo
       activities reviews_api_attribute is_blocked)
  end

  def self.index_api_attributes
    %i(uid email_api_attribute_alias first_name short_name shortened_last_name user_type
       gender birthdate bio location
       profile_photo background_photo
       activities reviews_api_attribute)
  end

  def self.nested_api_attributes
    index_api_attributes - %i(activities)
  end

  def self.self_api_attributes
    %i(uid email sign_in_count user_type first_name last_name
       has_guide_experience has_guide_certifications has_ach
       gender birthdate bio location activities latitude longitude
       profile_photo background_photo is_using_oauth reviews_api_attribute
       phone_number_api_attribute cards
       email_alias notification_setting is_verified_guide is_verified_adventurer
       credit_amount users_roles_api_attribute)
  end

  def self.chat_api_attributes
    %i(uid email first_name short_name shortened_last_name chats)
  end

  def self.auth_api_attributes
    self_api_attributes + %i(auth_token_api_attribute)
  end

  def self.chat_nested_api_attributes
    nested_api_attributes + %i(slug phone_number_api_attribute)
  end

  def auth_token_api_attribute
    "#{uid}.#{auth_token}" if auth_token.present?
  end

  def ensure_auth_token
    self.auth_token = generate_auth_token if auth_token.blank?
  end

  def ensure_auth_token!
    ensure_auth_token && save!
  end

  def ensure_notification_setting
    self.notification_setting ||= self.build_notification_setting
  end

  def activity_uids= uids
    activity_ids = Activity.where(uid: uids).pluck(:id)
    self.activity_ids = activity_ids
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def name= value
    self.first_name, self.last_name = String(value).split(' ', 2)
  end

  def display_name
    name.presence || email
  end

  def short_name
    "#{first_name} #{shortened_last_name}".strip
  end

  def shortened_last_name
    last_name.try(:strip).try(:[], 0).try(:+, '.')
  end

  def update_with_password(params, *options)
    if is_using_oauth
      forced_update_without_password(params.except(:current_password), *options)
    else
      super
    end
  end

  def forced_update_without_password(params, *options)
    result = update_attributes(params, *options)
    clean_up_passwords
    result
  end

  def password=(new_password)
    self.is_using_oauth = false unless new_record?
    super
  end

  def reviews_api_attribute
    Hash[*users_roles.includes(:role).map { |ur| [ur.role_name, ur.reviews_api_attribute] }.flatten(2)]
  end

  def notify_email_updated
    if email_was.present? && email_notification
      UserMailer.notify_updated_email(self, email_was)
                .deliver_later
    end
  end

  def confirmed?
    true
  end

  protected

  def confirmation_required?
    false
  end

  def send_password_change_notification?
    super && email_notification
  end

  def send_confirmation_notification?
    !@skip_confirmation_notification && self.email.present? && email_notification
  end

  private

  def slug_candidates
    [
      [first_name, last_name.try(:strip).try(:[], 0)],
      [first_name, last_name.try(:strip).try(:[], 0), id]
    ]
  end

  def generate_auth_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(auth_token: token).exists?
    end
  end

  def generate_random(n)
    SecureRandom.urlsafe_base64(n)
  end

  def ensure_email_alias
    loop do
      name = SecureRandom.urlsafe_base64(4, false).downcase
      domain = ENV.fetch('EMAIL_ALIAS_DOMAIN', 'reply.gohinterlands.com')
      self.email_alias = "#{name}@#{domain}"
      break unless self.class.exists?(email_alias: email_alias)
    end
  end

  def add_to_mixpanel
    AddToMixpanelJob.perform_later id
  end

  def update_mixpanel
    if (changed & %w(first_name last_name gender birthdate location email_alias phone_number)).present?
      add_to_mixpanel
    end
  end

  def add_mailchimp_subscriber
    SubscribeUserToMailingListJob.perform_later(self)
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def email_required?
    true
  end
end

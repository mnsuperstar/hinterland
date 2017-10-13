# == Schema Information
#
# Table name: companies
#
#  id                      :integer          not null, primary key
#  name                    :string
#  email                   :string
#  phone_number            :string
#  address                 :string
#  custom_domain           :string
#  custom_domain_candidate :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  uid                     :string
#  slug                    :string
#  logo                    :string
#  facebook                :string
#  twitter                 :string
#  instagram               :string
#  linkedin                :string
#  tracking_id             :string
#  stripe_customer_id      :string
#

class Company < ApplicationRecord
  include FriendlyId

  include HasUid
  include HasApi
  include HasStripeCustomer

  has_many :guides, class_name: 'User', foreign_key: "company_id", dependent: :destroy
  has_many :adventures, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :cards, as: :owner, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :stripe_accounts, dependent: :destroy
  has_many :admin_companies, dependent: :destroy
  has_many :received_charges, class_name: 'Charge', foreign_key: "receiver_id", dependent: :destroy
  has_many :guests, dependent: :destroy

  has_one :stripe_account, dependent: :destroy
  has_one :stripe_subscription, dependent: :destroy
  has_one :stripe_plan, through: :stripe_subscription

  accepts_nested_attributes_for :admin_companies, :stripe_subscription, :cards

  scope :matched_domain, -> (domain) { where("slug = :domain_val OR custom_domain = :domain_val", domain_val: domain.remove('.com')).any? }
  scope :used, -> (domain) { find_by(slug: domain.remove('.com')) }
  scope :has_valid_ach, -> { joins(:stripe_account).where.not(stripe_accounts: { address_postal_code: nil }) }
    scope :has_invalid_ach, -> {
      joins("LEFT JOIN stripe_accounts ON stripe_accounts.company_id = companies.id")
        .where(stripe_accounts: { address_postal_code: nil })
    }
    scope :need_ach_reminder, -> {
      has_invalid_ach
        .where('reminded_at <= :time OR (reminded_at IS NULL AND companies.created_at <= :time)', {time: 7.days.ago.end_of_day})
    }

  validates :admin_companies, length: { minimum: 1 }

  friendly_id :slug_candidates, use: :slugged
  mount_uploader :logo, LogoUploader

  before_save :set_custom_domain, if: :custom_domain_candidate_changed?

  delegate :update_stripe_balance, to: :stripe_account, prefix: false, allow_nil: true

  def self.find_by_domain! domain_name
    if domain_name =~ /\.#{ENV['APP_DOMAIN']}/ # default hinterlands subdomain
      find_by!(slug: domain_name.split('.', 2)[0])
    else # company's custom domain
      find_by!(custom_domain: domain_name)
    end
  end

  def self.api_attributes
    %i(name email phone_number address custom_domain_candidate
      logo facebook twitter instagram linkedin tracking_id)
  end

  def self.admin_api_attributes
    api_attributes + %i(stripe_subscription cards admin_companies)
  end

  def can_list_adventure?
    true
  end

  def has_bank_account?
    stripe_account.try(:address_postal_code).present?
  end

  def has_ach
    has_valid_ach?
  end

  alias_method :has_valid_ach?, :has_bank_account?

  def company=(string)
    self.name = string
  end

  private

  def set_custom_domain

  end

  def slug_candidates
    [
      name,
      [name, SecureRandom.urlsafe_base64(1).downcase],
      [name, SecureRandom.urlsafe_base64(3).downcase]
    ]
  end
end

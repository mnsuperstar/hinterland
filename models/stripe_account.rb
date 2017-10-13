# == Schema Information
#
# Table name: stripe_accounts
#
#  id                      :integer          not null, primary key
#  user_id                 :integer
#  account_id              :string
#  secret_key              :string
#  publishable_key         :string
#  charges_enabled         :boolean          default(FALSE)
#  transfers_enabled       :boolean          default(FALSE)
#  verified                :boolean          default(FALSE)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  uid                     :string
#  stripe_balance_cents    :integer          default(0), not null
#  stripe_balance_currency :string           default("USD"), not null
#  bank_account_last4      :string
#  address_line1           :string
#  address_line2           :string
#  address_city            :string
#  address_state           :string
#  address_postal_code     :string
#  address_country         :string
#  stripe_error            :string
#  company_id              :integer
#

class StripeAccount < ApplicationRecord
  include HasUid
  include HasApi
  include HasCompany

  has_many :stripe_events, as: :subject, dependent: :nullify
  belongs_to :user
  has_many :withdraws, dependent: :nullify

  monetize :stripe_balance_cents

  validates :user, presence: true
  validates :tos_accepted, acceptance: true
  validate :service_account_validity

  attr_accessor :service_account

  before_destroy :destroy_on_stripe # make sure we can remove the account on stripe
  after_destroy :unlist_adventures
  after_save :send_email_notifications
  after_commit :create_on_stripe, on: [:create]
  after_commit :update_on_stripe, on: [:update]

  def self.api_attributes
    %i(uid charges_enabled transfers_enabled verified bank_account_last4 stripe_error)
  end

  (HinStripe::Account.attr_names - [:id]).each do |name|
    define_method(name) do
      service_account.try(name)
    end

    define_method("#{name}=") do |value|
      retrieve_service_account.assign_attributes name => value
    end
  end

  def retrieve_service_account
    self.service_account ||= account_id.present? ? HinStripe::Account.find(account_id) : HinStripe::Account.new
  end

  def account
    return nil if account_id.blank?
    @account ||= Stripe::Account.retrieve(account_id)
  end

  def update_stripe_balance
    UpdateStripeBalanceJob.perform_later(self)
  end

  private

  def service_account_validity
    service_account.errors.each{|k,v| errors.add(k, v) } if errors.empty? &&
                                                              (service_account || new_record?) &&
                                                              retrieve_service_account.invalid?
  end

  def destroy_on_stripe
    if account.delete.deleted
      self.account_id = nil
    else
      raise ActiveRecord::Rollback
    end if account
  end

  def create_on_stripe
    StripeAccountSyncJob.perform_later('create', self, service_account.attributes) if service_account
  end

  def update_on_stripe
    StripeAccountSyncJob.perform_later('update', self, service_account.attributes) if service_account
  end

  def send_email_notifications
    disabled_attributes = []
    %w(charges_enabled transfers_enabled verified).each do |attr|
      disabled_attributes << attr if send("#{attr}_was") && !send(attr)
    end
    AdminMailer.stripe_account_disabled(self, disabled_attributes).deliver_later unless disabled_attributes.empty?
  end

  def unlist_adventures
    user.adventures.each do |adventure|
      adventure.unlist
    end if user
  end
end

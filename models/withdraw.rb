# == Schema Information
#
# Table name: withdraws
#
#  id                       :integer          not null, primary key
#  uid                      :string           not null
#  stripe_account_id        :integer
#  user_id                  :integer          not null
#  status                   :integer          default("pending"), not null
#  stripe_id                :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  amount_cents             :integer          default(0), not null
#  amount_currency          :string           default("USD"), not null
#  amount_reversed_cents    :integer          default(0), not null
#  amount_reversed_currency :string           default("USD"), not null
#

class Withdraw < ApplicationRecord
  include HasUid
  include HasApi
  belongs_to :stripe_account
  belongs_to :user
  enum status: %i(pending in_transit paid canceled failed)

  monetize :amount_cents
  monetize :amount_reversed_cents
  scope :filter_status, -> (status) { where(status: statuses[status]) }

  validates :user, :stripe_account, :amount_cents, presence: true
  validate :no_other_pending_withdraws, on: :create
  validate :amount_validity

  before_create :create_stripe_transfer
  after_update :update_user_balance, if: -> (w) { w.paid? && (w.amount_cents_changed? || w.amount_reversed_cents_changed? || w.status_changed?) }

  def self.api_attributes
    %i(uid amount amount_reversed status)
  end

  # lock currency to USD
  def amount_currency
    'USD'
  end

  def destination_account_id
    stripe_account.account.try(:external_accounts).try(:data).try(:first).try(:id)
  end

  def stripe_transfer
    return nil if stripe_id.blank?
    @stripe_transfer ||= Stripe::Transfer.retrieve(stripe_id)
  end

  def reverse
    if paid?
      errors.add(:base, :reverse_paid)
      false
    else
      reversal = stripe_transfer.reversals.create # support only full reversal for now
      update_attributes(amount_reversed_cents: reversal.amount)
    end
  end

  private

  def amount_validity
    errors.add(:amount, :greater_than, count: 0) if amount_cents <= 0
    errors.add(:amount, :less_than_or_equal_to, count: stripe_account.stripe_balance) if stripe_account && amount > stripe_account.stripe_balance
  end

  def no_other_pending_withdraws
    errors.add(:base, :pending_withdraw_exists) if user && user.withdraws.where(status: [Withdraw.statuses[:pending], Withdraw.statuses[:in_transit]]).exists?
  end

  def create_stripe_transfer
    transfer = Stripe::Transfer.create(amount: amount_cents,
                                       currency: amount_currency,
                                       destination: destination_account_id)
    self.stripe_id = transfer.id
    self.amount_cents = transfer.amount
    self.status = transfer.status
  end

  def update_user_balance
    stripe_account.try(:update_stripe_balance)
  end
end

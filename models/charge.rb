# == Schema Information
#
# Table name: charges
#
#  id                       :integer          not null, primary key
#  uid                      :string           not null
#  amount_cents             :integer          default(0), not null
#  amount_currency          :string           default("USD"), not null
#  amount_refunded_cents    :integer          default(0), not null
#  amount_refunded_currency :string           default("USD"), not null
#  fee_cents                :integer          default(0), not null
#  fee_currency             :string           default("USD"), not null
#  stripe_id                :string
#  sender_id                :integer
#  receiver_id              :integer
#  status                   :integer          default("pending"), not null
#  booking_id               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class Charge < ApplicationRecord
  include HasApi
  include HasUid

  enum status: [:pending, :succeeded, :failed, :canceled]

  monetize :amount_cents, :amount_refunded_cents, :fee_cents

  belongs_to :booking
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "Company", foreign_key: "receiver_id"

  before_create :create_stripe_charge, if: :from_adventurer?
  after_commit :create_stripe_special_transfer, on: [:create], if: :from_hinterlands?

  validates :receiver, :booking, presence: true

  def self.api_attributes
    %i(uid booking amount fee sender receiver)
  end

  # lock currency to USD
  def amount_currency
    'USD'
  end

  def capture!
    return if stripe_id.blank?

    StripeChargeJob.perform_later('capture', self) if from_adventurer?
  end

  def refund!
    return if stripe_id.blank?

    if from_adventurer?
      StripeChargeJob.perform_later('refund', self, stripe_id)
    else
      StripeSpecialTransferWorker.perform_async(id, 'refund')
    end
  end

  def recreate_stripe_charge!
    refund!
    self.stripe_id = nil
    create_stripe_charge
    save!
  end

  def from_adventurer?
    !sender_id.nil?
  end

  def from_hinterlands?
    sender_id.nil?
  end

  private

  def create_stripe_charge
    return if amount_cents <= 0

    charge_stripe = Stripe::Charge.create(
      amount: amount_cents,
      currency: amount_currency,
      customer: booking.card.owner.stripe_customer_id,
      source: booking.card.stripe_id,
      destination: receiver.stripe_account.account_id,
      application_fee: booking.service_fee_cents,
      capture: false
    )
    assign_charge_value charge_stripe
  end

  def create_stripe_special_transfer
    return if amount_cents <= 0

    StripeSpecialTransferWorker.perform_async(id)
  end

  def assign_charge_value charge
    self.amount_refunded = charge.amount_refunded
    self.fee = charge.application_fee
    self.stripe_id = charge.id
  end
end

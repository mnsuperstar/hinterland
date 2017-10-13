# == Schema Information
#
# Table name: booking_tips
#
#  id            :integer          not null, primary key
#  booking_id    :integer
#  card_id       :integer
#  tips_cents    :integer          default(0), not null
#  tips_currency :string           default("USD"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  stripe_id     :string
#

class BookingTip < ApplicationRecord
  include HasApi
  MINIMUM_TIPS = 100

  belongs_to :booking
  belongs_to :card
  monetize :tips_cents

  before_validation :ensure_card
  before_save :charge_tips

  validates :booking, :tips_cents, :card, presence: true
  validate :minimum_tips
  validate :ensure_past_booking
  validate :ensure_accepted_booking

  attr_accessor :card_uid

  private

  def charge_tips
    self.stripe_id = stripe_charge.id
  end

  def amount_currency
    'USD'
  end

  def stripe_charge
    @stripe_charge = Stripe::Charge.create(
      amount: tips_cents,
      currency: amount_currency,
      customer: customer,
      source: card.stripe_id,
      destination: guide_account,
      capture: true
    )
  end

  def customer
    card.owner.stripe_customer_id
  end

  def guide_account
    booking.guide.stripe_account.account_id
  end

  def ensure_card
    return unless booking
    self.card = booking.adventurer.cards.find_by(uid: card_uid)
  end

  def minimum_tips
    errors.add :tips_cents, :minimum_tips, minimum_tips: Money.new(MINIMUM_TIPS).format if tips_cents < MINIMUM_TIPS
  end

  def  ensure_accepted_booking
    return unless booking
    unless booking.accepted?
      errors.add(:booking, :accepted)
    end
  end

  def  ensure_past_booking
    return unless booking
    unless booking.past?
      errors.add(:booking, :past)
    end
  end
end

module BookingReferralCredit
  extend ActiveSupport::Concern
  included do
    has_many :credit_histories, as: :source, dependent: :nullify

    after_create :subtract_credit_amount

    monetize :credit_amount_cents, :disable_validation => true
  end

  def refund_credit_amount
    return if credit_amount_cents.zero?
    adventurer.add_credit_amount! credit_amount, source: self, reason: 'booking_refund'
    update_column :credit_amount_cents, 0
  end

  private

  def subtract_credit_amount
    return if credit_amount_cents.zero?
    adventurer.add_credit_amount! -credit_amount, source: self, reason: 'booking_payment'
  end
end

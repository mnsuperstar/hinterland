module HasCharge
  extend ActiveSupport::Concern

  included do
    has_many :charges, dependent: :nullify
    has_one :charge, -> { where.not(sender: nil) }, class_name: "Charge"
    has_one :hinterlands_charge, -> { where(sender: nil) }, class_name: "Charge"

    before_save :ensure_charge,
      if: proc{ |booking| (booking.charge.nil? || total_price_cents_changed?) && !booking.card.nil? }
    after_update :determine_transaction, :ensure_apple_pay_destroyed,
      unless: proc {|booking| booking.pending? }

    validates_associated :charges
    validate :price_changes_allowance, on: :update
  end

  private

  def ensure_apple_pay_destroyed
    return unless status_changed?
    card.destroy if card.try(:apple_pay?)
  end

  def determine_transaction
    return unless status_changed?
    if accepted?
      if (discount_cents > 0 || credit_amount_cents > 0) && hinterlands_charge.nil?
        charge_amount = (discount_cents + credit_amount_cents + [total_price_cents - service_fee_cents, 0].min).to_i
        charges.create!(amount_cents: charge_amount, receiver: company)
      end
      charge.capture!
      schedule_commit_tax
    else
      charges.each(&:refund!)
      refund_credit_amount
      schedule_cancel_tax
    end
  end

  def ensure_charge
    return if canceled? || rejected?
    if charge && total_price_cents_changed?
      charge.update!(amount_cents: total_price_cents)
      charge.recreate_stripe_charge!
    elsif charge.nil? && (pending? || accepted?)
      charges.build(amount_cents: total_price_cents, sender: adventurer,
        receiver: company)
    end
  end

  def price_changes_allowance
    errors.add(:base, :non_pending_price_change) if !pending? && (total_price_cents_changed? || discount_cents_changed? || credit_amount_cents_changed?)
  end
end

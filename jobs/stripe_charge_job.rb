class StripeChargeJob < ApplicationJob
  queue_as :default

  def perform(operation, charge, stripe_id = charge.stripe_id)
    case operation
    when 'capture'
      begin
        Stripe::Charge.retrieve(stripe_id).capture
        charge.receiver.update_stripe_balance
      rescue Stripe::InvalidRequestError => e
        raise unless e.message.include?('has already been captured')
      end
    when 'refund'
      begin
        Stripe::Refund.create(
          charge: stripe_id,
          refund_application_fee: charge.fee_cents.nonzero?
        )
        charge.receiver.update_stripe_balance
      rescue Stripe::InvalidRequestError => e
        raise unless e.message.include?('has already been refunded')
      end
    else
      raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end

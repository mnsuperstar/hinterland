class StripeSpecialTransferWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(charge_id, action = 'create')
    charge = Charge.find_by(id: charge_id)
    return if charge.nil?

    case action
    when "create"
      begin
        transfer = Stripe::Transfer.create(
                     amount: charge.amount_cents,
                     currency: charge.amount_currency,
                     destination: charge.receiver.stripe_account.account_id
                   )

        if transfer
          charge.update!(stripe_id: transfer.id)
        else
          AdminMailer.special_transfer_failed(charge, "Charge cannot be transfered").deliver_now
          raise StandardError, "Charge cannot be transfered"
        end
      rescue => e
        AdminMailer.special_transfer_failed(charge, e.message).deliver_now if action == 'create'
        raise e
      end
    when "refund"
      transfer = Stripe::Transfer.retrieve(charge.stripe_id)
      transfer.reversals.create
    end
  end
end

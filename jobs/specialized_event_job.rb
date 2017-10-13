class SpecializedEventJob < ApplicationJob
  queue_as :default

  attr_accessor :stripe_event

  def perform(stripe_event)
    self.stripe_event = stripe_event
    case stripe_event.event_type
    when 'account.updated'
      account_updated
    when /^transfer\./
      transfer_updated
    when /^charge\.[^\.]+$/ # ignore charge.dispute events
      charge_updated
    when 'account.application.deauthorized'
      account_id = stripe_event.data['object']['id']
      stripe_account = StripeAccount.find_by(account_id: account_id)
      if stripe_account
        stripe_account.send(:unlist_adventures)
        stripe_account.delete
      end
    end
  end

  private

  def account_updated
    account_id = stripe_event.data['object']['id']

    stripe_account = StripeAccount.find_by!(account_id: account_id)

    service_account = HinStripe::Account.find(account_id)
    address = service_account.stripe_account.legal_entity[:address]
    stripe_account.update_attributes!(charges_enabled: service_account.charges_enabled,
                                      transfers_enabled: service_account.transfers_enabled,
                                      verified: service_account.verified,
                                      bank_account_last4: service_account.bank_account_last4,
                                      address_line1: address[:line1],
                                      address_line2: address[:line2],
                                      address_city: address[:city],
                                      address_state: address[:state],
                                      address_postal_code: address[:postal_code],
                                      address_country: address[:country])
    stripe_event.update_attributes! subject: stripe_account, processed_at: DateTime.now
  end

  def transfer_updated
    object = stripe_event.data['object']
    withdraw = Withdraw.find_by(stripe_id: object['id'])
    return if withdraw.nil?
    withdraw.update_attributes!(status: object['status'],
                                amount_cents: object['amount'])
    stripe_event.update_attributes! subject: withdraw, processed_at: DateTime.now
  end

  def charge_updated
    object = stripe_event.data['object']
    charge = Charge.find_by(stripe_id: object['id'])
    if charge
      if object['refunded']
        charge.status = 'canceled'
      elsif object['captured']
        charge.status = 'succeeded'
      elsif object['status'] == 'failed'
        charge.status = 'failed'
      else
        charge.status = 'pending'
      end
      charge.update_attributes(amount_cents: object['amount'],
                                amount_refunded_cents: object['amount_refunded'],
                                fee_cents: object['application_fee'].to_i)
      stripe_event.update_attributes! subject: charge, processed_at: DateTime.now
    end
  end
end

class StripeAccountSyncJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveJob::DeserializationError) do
    # ignore when stripe_account no longer exists
  end

  def perform(action, stripe_account, attributes)
    service_account = stripe_account.retrieve_service_account
    attributes.except!("managed", :managed) if action.to_s == 'update'
    service_account.assign_attributes(attributes)
    if service_account.save
      address = service_account.stripe_account.legal_entity[:address]
      stripe_attributes = {
        account_id: service_account.id,
        charges_enabled: service_account.charges_enabled,
        transfers_enabled: service_account.transfers_enabled,
        verified: service_account.verified,
        bank_account_last4: service_account.bank_account_last4,
        address_line1: address[:line1],
        address_line2: address[:line2],
        address_city: address[:city],
        address_state: address[:state],
        address_postal_code: address[:postal_code],
        address_country: address[:country],
        stripe_error: nil
      }

      if action.to_s == 'create'
        stripe_attributes.merge!(secret_key: service_account.secret_key,
                                 publishable_key: service_account.publishable_key)
      end

      stripe_account.update_columns(stripe_attributes)
    else # may fail if rejected by stripe
      stripe_account.update_column :stripe_error, service_account.errors.full_messages.join(',')
      raise ActiveModel::ValidationError.new(service_account)
    end
  end
end

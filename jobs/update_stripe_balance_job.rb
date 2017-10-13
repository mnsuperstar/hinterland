class UpdateStripeBalanceJob < ApplicationJob
  queue_as :default

  def perform(account)
    return if account.try(:secret_key).blank?
    api_key = account.secret_key
    balance = Stripe::Balance.retrieve api_key: api_key
    account.update_column :stripe_balance_cents, balance.available.sum(&:amount)
  end
end

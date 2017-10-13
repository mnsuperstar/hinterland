module HasStripeCustomer
  extend ActiveSupport::Concern

  included do
    before_destroy :delete_stripe_customer
  end

  def create_stripe_customer!
    return if stripe_customer_id.present?
    stripe_customer = Stripe::Customer.create(email: email, description: id)
    update_column(:stripe_customer_id, stripe_customer.id)
  end

  def delete_stripe_customer
    return if stripe_customer_id.blank?
    stripe_customer = Stripe::Customer.retrieve(stripe_customer_id)
    stripe_customer.delete
  end
end

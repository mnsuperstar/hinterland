# == Schema Information
#
# Table name: stripe_subscriptions
#
#  id              :integer          not null, primary key
#  subscription_id :string
#  status          :integer          default("trialing"), not null
#  company_id      :integer
#  stripe_plan_id  :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  uid             :string
#

class StripeSubscription < ApplicationRecord
  include HasApi
  include HasUid
  include HasCompany

  belongs_to :stripe_plan

  enum status: [:trialing, :active, :past_due, :canceled, :unpaid]

  validates :stripe_plan, presence: true

  after_create :process_subscription

  def self.api_attributes
    %i(uid status stripe_plan)
  end

  def stripe_plan_uid=(uid)
    self.stripe_plan = StripePlan.find_by_uid(uid)
  end

  def process_subscription
    stripe_subscription = Stripe::Subscription.create(
                            customer: company.stripe_customer_id,
                            plan: stripe_plan.plan_id,
                            tax_percent: AppSetting['subscription.tax_percents']
                          )
    self.update_columns(subscription_id: stripe_subscription.id,
                        status: stripe_subscription.status) if stripe_subscription
  end
end

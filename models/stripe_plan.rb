# == Schema Information
#
# Table name: stripe_plans
#
#  id                :integer          not null, primary key
#  plan_id           :string
#  plan_type         :integer          default("solo"), not null
#  trial_period_days :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  amount_cents      :integer          default(0), not null
#  amount_currency   :string           default("USD"), not null
#  uid               :string
#

class StripePlan < ApplicationRecord
  include HasApi
  include HasUid

  has_many :stripe_subscription, dependent: :destroy
  has_many :companies, through: :stripe_subscription

  enum plan_type: [:solo, :company]
  monetize :amount_cents

  validates :plan_type, :amount, :trial_period_days, presence: true

  after_create :process_plan
  after_update :update_plan_name
  before_destroy :delete_plan

  def self.api_attributes
    %i(uid plan_type amount trial_period_days)
  end

  def process_plan
    stripe_plan = Stripe::Plan.create(
                  amount: amount_cents,
                  currency: amount_currency,
                  interval: "month",
                  name: plan_type,
                  id: uid,
                  trial_period_days: trial_period_days
                )
    self.update_columns(plan_id: stripe_plan.id) if stripe_plan
  end

  def update_plan_name
    plan = Stripe::Plan.retrieve(plan_id)
    plan.name = plan_type
    plan.save
  end

  def delete_plan
    Stripe::Plan.retrieve(plan_id).delete
  end
end

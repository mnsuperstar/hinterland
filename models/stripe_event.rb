# == Schema Information
#
# Table name: stripe_events
#
#  id               :integer          not null, primary key
#  event_id         :string
#  event_created    :datetime
#  data             :text
#  livemode         :boolean
#  pending_webhooks :integer
#  request          :string
#  event_type       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  subject_id       :integer
#  subject_type     :string
#  stripe_user_id   :string
#  processed_at     :datetime
#

class StripeEvent < ApplicationRecord
  belongs_to :subject, polymorphic: true

  serialize :data, Hash

  after_commit :process_event, on: [:create]

  validate :livemode_validity

  def self.create_from_stripe_event_id! id, stripe_user_id = nil
    api_key = StripeAccount.find_by(account_id: stripe_user_id).try(:secret_key)
    raw_event = Stripe::Event.retrieve id, api_key: api_key || Stripe.api_key
    create!(event_id: id,
            event_created: Time.at(raw_event.created),
            stripe_user_id: raw_event['user_id'],
            data: raw_event.data.as_json,
            livemode: raw_event.livemode,
            event_type: raw_event.type,
            request: raw_event.request,
            pending_webhooks: raw_event.pending_webhooks)
  end

  def self.create_from_webhook_params params
    create!(event_id: params[:id],
            event_created: Time.at(params[:created].to_i),
            stripe_user_id: params[:user_id],
            data: params[:data].as_json,
            livemode: params[:livemode],
            event_type: params[:type],
            request: params[:request],
            pending_webhooks: params[:pending_webhooks])
  end

  private

  def livemode_validity
    errors.add(:livemode, 'should be true in production') if Rails.env.production? && !livemode
  end

  def process_event
    SpecializedEventJob.perform_later(self)
  end
end

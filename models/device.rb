# == Schema Information
#
# Table name: devices
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  uid              :string
#  endpoint_arn     :string
#  token            :string
#  os               :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  is_disabled      :boolean          default(FALSE), not null
#  subscription_arn :string
#  company_id       :integer
#

class Device < ApplicationRecord
  include HasUid
  include HasApi
  include HasCompany

  belongs_to :user

  before_create :register_endpoint
  before_destroy :delete_endpoint
  before_update :update_endpoint
  after_commit :subscribe_topic, on: [:create]
  after_destroy :unsubscribe_topic

  scope :enabled, -> { where(is_disabled: false) }

  def self.api_attributes
    %i(uid endpoint_arn token os is_disabled)
  end

  def self.send_message(message, options = {})
    enabled.each do |device|
      device.send_message(message, options)
    end
  end

  def push_notification
    @push_notification ||= PushNotification.new(self)
  end

  def send_message(message, options = {})
    return if is_disabled
    push_notification.send_message message, options
  rescue Aws::SNS::Errors::EndpointDisabled
    update_column :is_disabled, true
  end

  def ios?
    os == 'ios'
  end

  private

  def subscribe_topic
    unsubscribe_topic if subscription_arn.present?
    AwsTopicSubscriptionJob.perform_later('subscribe', self)
  end

  def unsubscribe_topic
    AwsTopicSubscriptionJob.perform_later('unsubscribe', subscription_arn) if subscription_arn.present?
  end

  def register_endpoint
    register do
      endpoint = push_notification.register_endpoint
      self.endpoint_arn = endpoint.endpoint_arn
    end
  rescue Aws::SNS::Errors::InvalidParameter => e
    errors.add(:base, e.message)
    throw(:abort)
  end

  def update_endpoint
    if token_changed? || (is_disabled_changed? && !is_disabled)
      push_notification.update_endpoint
    end
  rescue Aws::SNS::Errors::ServiceError => e
    errors.add(:base, e.message)
  end

  def register
    valid_for_register? && yield
  end

  def valid_for_register?
    token.present? && os.present? && endpoint_arn.nil?
  end

  def delete_endpoint
    push_notification.delete_endpoint
    self.endpoint_arn = nil
  end
end

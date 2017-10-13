class AwsTopicSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(action, device_or_arn)
    raise "SNS_GLOBAL_TOPIC ENV not set" if ENV['SNS_GLOBAL_TOPIC'].blank?

    case action.to_s
    when 'subscribe'
      device = device_or_arn
      result = device.push_notification.subscribe
      device.update_column :subscription_arn, result.subscription_arn
    when 'unsubscribe'
      Device.new.push_notification.unsubscribe(device_or_arn)
    end
  end
end

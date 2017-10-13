class PushNotification
  module MessageSender
    def send_message message, options
      sns.publish publish_attrs message, options
    end

    def publish_attrs message, options
      {
        message: prepared_message(message, options),
        message_structure: 'json'
      }.tap do |h|
        h.merge!(target)
        h.merge!(options.slice(:subject))
      end
    end

    def prepared_message message, options
      {default: message}.tap do |h|
        if ios?
          ios_options = ios_options_for(message, options)
          h.merge!(
            APNS_SANDBOX: ios_options.to_json,
            APNS: ios_options.to_json
          )
        end
      end.to_json
    end

    def ios_options_for(message, options)
      h = {
        sound: options[:sound].presence || 'default',
        aps: {}
      }
      h[:aps][:alert] = message
      h[:aps][:badge] = options[:badge] if options[:badge].present?
      h[:extra] = options[:extra] if options[:extra].present?
      h
    end

    def sns
      @sns ||= Aws::SNS::Client.new
    end

    def ios?
      true
    end
  end

  class Broadcaster
    include MessageSender
    def target
      { topic_arn: ENV['SNS_GLOBAL_TOPIC'] }
    end
  end

  attr_accessor :device
  include MessageSender

  def initialize(device)
    @device = device
  end

  def register_endpoint
    sns.create_platform_endpoint(
      {
        platform_application_arn: ENV[env_platform_arn],
        token: device.token,
        attributes: {
          'CustomUserData' => device.to_json(only: [:id, :uid])
        }
      }
    )
  end

  def delete_endpoint
    sns.delete_endpoint({endpoint_arn: device.endpoint_arn})
  end

  def update_endpoint
    sns.set_endpoint_attributes(
      {
       endpoint_arn: device.endpoint_arn,
       attributes: {'Enabled' => 'true', Token: device.token}
      }
    )
  end

  def subscribe(topic_arn = ENV['SNS_GLOBAL_TOPIC'])
    sns.subscribe({
      topic_arn: topic_arn,
      protocol: 'application',
      endpoint: device.endpoint_arn
    })
  end

  def unsubscribe subscription_arn = device.subscription_arn
    sns.unsubscribe({
      subscription_arn: subscription_arn
    })
  end

  private

  def ios?
    device.ios?
  end

  def target
    { target_arn: device.endpoint_arn }
  end

  def env_platform_arn
    device.os.upcase + '_ARN'
  end
end

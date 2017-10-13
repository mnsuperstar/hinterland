class SlackNotifierJob < ApplicationJob
  queue_as :default

  def perform(message)
    notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_URL'], username: "API #{Rails.env.titlecase}"
    notifier.ping message
  end
end

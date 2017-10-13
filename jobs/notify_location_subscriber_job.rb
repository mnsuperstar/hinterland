class NotifyLocationSubscriberJob < ApplicationJob
  queue_as :default

  def perform(adventure)
    location_subscriptions = LocationSubscription.where(notified_at: nil).nearby_from_adventure(adventure)
    location_subscriptions.each do |ls|
      ls.notify adventure
    end if location_subscriptions
  end
end

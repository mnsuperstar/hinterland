# == Schema Information
#
# Table name: location_subscriptions
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  latitude    :decimal(9, 6)    not null
#  longitude   :decimal(9, 6)    not null
#  notified_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class LocationSubscription < ApplicationRecord
  belongs_to :user

  acts_as_mappable default_units: :miles,
                   lat_column_name: :latitude,
                   lng_column_name: :longitude

  validates :latitude, :longitude, :user, presence: true
  validate :adventurer_only

  def self.nearby_from_adventure adventure
    return nil unless adventure.location
    within((AppSetting['adventure.filter_max_distance_in_miles'] || 10).to_i, origin: [adventure.latitude, adventure.longitude])
  end

  def notify adventure
    UserMailer.notify_location_subscriber(user, adventure).deliver_later
    PushNotificationJob.perform_later(user,
                                      I18n.t(:location_open,
                                        scope: %i(notification location_subscription),
                                        location: adventure.location_name.presence || adventure.location.state
                                      ),
                                      extra: { type: 'location_subscription.open', location_uid: adventure.location.try(:uid) })
    update_column :notified_at, DateTime.now
  end

  private

  def adventurer_only
    errors.add(:user, :adventurer_only) if user && !user.adventurer?
  end
end

# == Schema Information
#
# Table name: locations
#
#  id             :integer          not null, primary key
#  latitude       :decimal(9, 6)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  longitude      :decimal(9, 6)
#  zipcode        :string
#  country_code   :string
#  city           :string
#  state          :string
#  street_address :string
#  province       :string
#  district       :string
#  full_address   :string
#  uid            :string
#

class Location < ApplicationRecord
  include HasApi
  include HasUid

  has_many :adventures, dependent: :nullify
  has_many :open_locations, dependent: :nullify


  before_save :reverse_geocode,
    if: -> (l) {
      !skip_reverse_geocode && l.latitude.present? && l.longitude.present? && l.latitude_changed? && l.longitude_changed?
    }
  after_save do
    adventures.each do |adventure|
      adventure.schedule_indexing('update')
      adventure.send(:notify_location_subscriber)
    end if latitude_changed? || longitude_changed?
  end
  scope :available, -> { joins(:open_locations) }

  attr_accessor :skip_reverse_geocode

  def self.api_attributes
    super - %i(id)
  end

  def name
    [zipcode, city, state, province, country_code].compact.join(', ')
  end

  def city_state
    [city, state].compact.join(', ')
  end

  private

  def reverse_geocode
    Geocoder.new.reverse_geocode(latitude, longitude).each do |c, v|
      send("#{c}=", v) if send(c).blank?
    end
  end
end

# == Schema Information
#
# Table name: open_locations
#
#  id          :integer          not null, primary key
#  uid         :string           not null
#  state       :string           not null
#  state_code  :string           not null
#  city        :string           not null
#  image       :string
#  created_at  :datetime
#  updated_at  :datetime
#  location_id :integer
#

class OpenLocation < ApplicationRecord
  include HasUid
  include HasApi

  validates :state, :state_code, presence: true
  validates :city, presence: true, uniqueness: true

  mount_uploader :image, OpenLocationUploader

  belongs_to :location

  scope :matches_location, -> (location) {
    where(city: location.city).where(state: location.state).or(where(state_code: location.state))
  }

  def self.api_attributes
    %i(uid state_code city image location)
  end
end

# == Schema Information
#
# Table name: pre_booking_urls
#
#  id                    :integer          not null, primary key
#  short_uid             :string
#  number_of_adventurers :integer
#  start_on              :date
#  end_on                :date
#  adventure_id          :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class PreBookingUrl < ApplicationRecord
  include HasApi

  belongs_to :adventure

  validates :short_uid, uniqueness: true

  before_save :ensure_short_uid

  def self.api_attributes
    %i(number_of_adventurers start_on end_on adventure_id short_url)
  end

  def adventure_uid=(uid)
    self.adventure = Adventure.find_by_uid(uid)
  end

  def ensure_short_uid
    self.short_uid = generate_short_uid if short_uid.blank?
  end

  def generate_short_uid
    length = 4
    loop do
      uid = SecureRandom.urlsafe_base64(length).downcase
      break uid unless PreBookingUrl.exists?(short_uid: uid)
      length += 1
    end
  end

  def short_url
    Rails.application.routes.url_helpers.shortened_pre_booking_url(short_uid, host: ENV['SHORTENER_DOMAIN'])
  end
end

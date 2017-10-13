# == Schema Information
#
# Table name: short_urls
#
#  id           :integer          not null, primary key
#  long_url     :string
#  short_uid    :string
#  access_count :integer          default(0)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class ShortUrl < ApplicationRecord
  before_save :ensure_short_uid

  def ensure_short_uid
    self.short_uid = generate_short_uid if short_uid.blank?
  end

  def generate_short_uid
    length = 4
    loop do
      uid = SecureRandom.urlsafe_base64(length).downcase
      break uid unless ShortUrl.exists?(short_uid: uid)
      length += 1
    end
  end

  def short_url
    Rails.application.routes.url_helpers.shorten_url(short_uid, host: ENV['SHORTENER_DOMAIN'])
  end
end

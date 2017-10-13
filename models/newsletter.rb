# == Schema Information
#
# Table name: newsletters
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Newsletter < ApplicationRecord
  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: Devise.email_regexp, allow_blank: true }
    after_commit :subscribe_app_mailing_list, on: [:create]

  private

  def subscribe_app_mailing_list
    SubscribeAppMailingListJob.perform_later(self)
  end
end

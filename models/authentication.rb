# == Schema Information
#
# Table name: authentications
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string           not null
#  uid        :string
#  email      :string
#  name       :string
#  token      :string
#  secret     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Authentication < ApplicationRecord
  belongs_to :user

  validates :user, :provider, presence: true
  validates :uid, uniqueness: { scope: [:provider] }, presence: true
end
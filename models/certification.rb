# == Schema Information
#
# Table name: certifications
#
#  id         :integer          not null, primary key
#  name       :string
#  photo      :string
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Certification < ApplicationRecord
  mount_uploader :photo, CertificationUploader

  include HasApi

  belongs_to :user

  validates :photo, :user, presence: true

  scope :validated, -> { where.not(name: nil) }

  def self.api_attributes
    %i(name photo)
  end
end

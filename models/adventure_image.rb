# == Schema Information
#
# Table name: adventure_images
#
#  id           :integer          not null, primary key
#  file         :string
#  order_number :integer
#  adventure_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  uid          :string           not null
#

class AdventureImage < ActiveRecord::Base
  mount_uploader :file, AdventureUploader

  include HasApi
  include HasUid

  scope :ordered, -> { order('order_number ASC NULLS LAST, id ASC') }

  belongs_to :adventure

  validates :adventure, :file, presence: true

  def self.api_attributes
    %i(uid file order_number)
  end
end

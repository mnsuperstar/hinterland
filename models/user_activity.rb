# == Schema Information
#
# Table name: user_activities
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  activity_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class UserActivity < ApplicationRecord
  belongs_to :user
  belongs_to :activity

  validates :user_id, uniqueness: {scope: :activity_id}
end

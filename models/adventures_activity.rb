# == Schema Information
#
# Table name: adventures_activities
#
#  id           :integer          not null, primary key
#  adventure_id :integer
#  activity_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class AdventuresActivity < ApplicationRecord
  belongs_to :adventure
  belongs_to :activity
end

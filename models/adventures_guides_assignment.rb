# == Schema Information
#
# Table name: adventures_guides_assignments
#
#  id           :integer          not null, primary key
#  adventure_id :integer
#  user_id      :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class AdventuresGuidesAssignment < ApplicationRecord
  belongs_to :adventure
  belongs_to :guide, class_name: "User", foreign_key: "user_id"
end

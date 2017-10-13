# == Schema Information
#
# Table name: adventures_users
#
#  adventure_id :integer
#  user_id      :integer
#  created_at   :datetime
#  updated_at   :datetime
#  id           :integer          not null, primary key
#

class AdventuresUser < ApplicationRecord
  belongs_to :adventure
  belongs_to :user
end

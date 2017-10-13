# == Schema Information
#
# Table name: blocked_users
#
#  id         :integer          not null, primary key
#  blocker_id :integer
#  blockee_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BlockedUser < ApplicationRecord
  belongs_to :blocker, class_name: 'User', foreign_key: 'blocker_id'
  belongs_to :blockee, class_name: 'User', foreign_key: 'blockee_id'

  scope :on_users, -> (user1, user2) { where(blocker: user1, blockee: user2).or(where(blocker: user2, blockee: user1)) }
  scope :on_user, -> (user) { where(blocker: user).or(where(blockee: user)) }
end

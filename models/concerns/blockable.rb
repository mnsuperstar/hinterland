module Blockable
  extend ActiveSupport::Concern
  included do
    has_many :received_blocks, class_name: 'BlockedUser', foreign_key: "blockee_id", dependent: :destroy
    has_many :blockers, through: :received_blocks
    has_many :created_blocks, class_name: 'BlockedUser', foreign_key: "blocker_id", dependent: :destroy
    has_many :blockees, through: :created_blocks
  end

  def blocker_or_blockee_ids
    @blocker_or_blockee_ids ||= BlockedUser.on_user(self).pluck(:blocker_id, :blockee_id).flatten - [id]
  end

  def is_blocked
    current_user && current_user.created_blocks.where(blockee: self).exists?
  end
end

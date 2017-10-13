# == Schema Information
#
# Table name: roles
#
#  id            :integer          not null, primary key
#  name          :string
#  resource_id   :integer
#  resource_type :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Role < ApplicationRecord
  AVAILABLE_ROLES = %w(adventurer guide)
  RESTRICTED_ROLES = %w(support)
  ALL_ROLES = AVAILABLE_ROLES + RESTRICTED_ROLES

  has_many :users_roles, dependent: :destroy
  has_many :users, through: :users_roles

  scope :available, -> { where(name: AVAILABLE_ROLES) }

  validate :allowed_name_check

  def name= value
    super(value.downcase)
  end

  private

  def allowed_name_check
    errors.add(:name, :invalid) unless name.in?(ALL_ROLES)
  end
end

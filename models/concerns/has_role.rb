module HasRole
  extend ActiveSupport::Concern

  included do
    has_many :users_roles, dependent: :destroy
    has_many :roles, through: :users_roles

    scope :with_role, -> (role) { joins(:roles).where(roles: { name: role }) }
    scope :supports, -> { with_role('support') }

    validates :user_type, presence: true

    before_validation :assign_default_user_type
  end

  module ClassMethods
    def first_chat_support
      supports.joins('LEFT JOIN user_chats ON user_chats.user_id = users.id').group('users.id').reorder('COUNT(user_chats.id) ASC').first
    end
  end

  def users_roles_api_attribute
    users_roles.map do |ur|
      {
        role_name: ur.role_name,
        is_verified: ur.is_verified
      }
    end
  end

  def has_role?(role)
    role_names.include?(role.downcase)
  end

  def role_names reload=false
    if reload || @role_names.nil?
      @role_names = roles.map(&:name) # Not using pluck so it's possible to have newly assigned roles (not yet persisted)
    end
    @role_names
  end

  def add_role role
    if role
      self.users_roles << users_roles.where(role: role).first_or_initialize.tap{|ur| ur.is_primary = true}
      self.role_names << role.name
      @role = role
    end
  end

  def role
    @role ||= roles.joins(:users_roles).reorder('users_roles.is_primary DESC NULLS LAST').first
  end

  def user_type=(value)
    add_role Role.available.where(name: value.downcase).first_or_create! rescue nil
  end

  def user_type
    role.try(:name)
  end

  def users_role_for role
    users_roles.joins(:role).find_by(roles: { name: role })
  end

  def is_verified
    users_role_for(user_type).try(:is_verified)
  end

  def reload
    @role_names = @role = nil
    super
  end

  private

  def assign_default_user_type
    self.user_type ||= 'adventurer'
  end
end

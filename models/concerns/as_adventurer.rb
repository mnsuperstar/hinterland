module AsAdventurer
  extend ActiveSupport::Concern
  included do
    has_many :adventures, dependent: :nullify
    has_many :created_bookings, as: :adventurer, class_name: 'Booking',dependent: :destroy
    has_many :cards, as: :owner, dependent: :destroy
    has_many :sent_charges, class_name: 'Charge', foreign_key: "sender_id", dependent: :destroy
    has_many :location_subscriptions, dependent: :destroy

    after_save :ensure_adventurer_confirmation
    after_commit :schedule_new_adventurer_welcome, on: [:create]

    scope :adventurers, -> { where(roles: {name: 'adventurer'}).joins(:roles) }
    scope :verified_adventurers, -> { adventurers.where(users_roles: { is_verified: true }) }
    scope :unverified_adventurers, -> { adventurers.where(users_roles: { is_verified: false }) }
  end

  module ClassMethods
    def adventurer_api_attributes
      %i(uid email_api_attribute_alias first_name short_name shortened_last_name user_type
        gender birthdate bio location phone_number_api_attribute_adventurer
        profile_photo background_photo
        activities reviews_api_attribute is_blocked)
    end

    def adventurer_index_api_attributes
      %i(uid email_api_attribute_alias first_name short_name shortened_last_name user_type
        gender birthdate bio location
        profile_photo background_photo
        activities reviews_api_attribute)
    end

    def adventurer_nested_api_attributes
      %i(uid email_api_attribute_alias first_name short_name shortened_last_name user_type
        bio location profile_photo reviews_api_attribute)
    end

    def with_adventurer_phone_number
      return all if current_user.nil?
      joins("LEFT JOIN bookings a_p_c_bookings ON a_p_c_bookings.adventurer_id = users.id AND a_p_c_bookings.guide_id = #{current_user.id}")
        .select('users.*')
        .select('(CASE WHEN COUNT(a_p_c_bookings.id) > 0 THEN users.phone_number ELSE NULL END) AS adventurer_phone_number')
        .group("users.id")
    end
  end

  def accepted_booking_with_guide(guide)
    created_bookings.accepted.find_by(guide: guide)
  end

  def adventurer?
    has_role? 'adventurer'
  end

  def is_verified_adventurer
    users_role_for('adventurer').try(:is_verified)
  end

  def phone_number_api_attribute_adventurer
    self[:adventurer_phone_number].try(:phony_formatted, format: :international)
  end

  private

  def adventurer_verified_will_change?
    confirmed_at_changed? || birthdate_changed? || phone_number_changed?
  end

  def ensure_adventurer_confirmation
    return if !has_role?('adventurer') || !adventurer_verified_will_change?

    if confirmed? && birthdate? && phone_number?
      users_role_for('adventurer').verify!
    else
      users_role_for('adventurer').unverify!
    end
  end

  def schedule_new_adventurer_welcome
    NotifyNewUserJob.set(wait_until: 24.hours.from_now).perform_later(self)
  end
end

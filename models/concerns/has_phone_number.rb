module HasPhoneNumber
  extend ActiveSupport::Concern

  included do
    phony_normalize :phone_number, default_country_code: 'US'
  end

  module ClassMethods
    # similar to with_guide_phone_number and with_adventurer_phone_number but heavier and applicable to all roles
    def with_phone_number
      return all if current_user.nil?
      joins("LEFT JOIN bookings u_p_c_bookings ON \
              (u_p_c_bookings.guide_id = users.id AND u_p_c_bookings.status = #{Booking.statuses[:accepted]} AND u_p_c_bookings.adventurer_id = #{current_user.id}) OR \
              (u_p_c_bookings.adventurer_id = users.id AND u_p_c_bookings.guide_id = #{current_user.id})")
        .select('users.*')
        .select("(CASE WHEN COUNT(u_p_c_bookings.id) > 0 THEN users.phone_number ELSE NULL END) AS phone_number")
        .group("users.id")
    end
  end

  def phone_number_api_attribute
    phone_number.try(:phony_formatted, format: :international)
  end
end

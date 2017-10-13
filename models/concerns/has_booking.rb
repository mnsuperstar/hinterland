module HasBooking
  extend ActiveSupport::Concern
  included do
    has_many :received_bookings, class_name: 'Booking', foreign_key: "guide_id"
    has_many :bookings, class_name: 'Booking', foreign_key: "adventurer_id"
  end
end

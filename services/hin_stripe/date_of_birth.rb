module HinStripe
  class DateOfBirth < Base
    define_attributes :day, :month, :year
    validates :day, :month, :year, presence: true
    validates :day, numericality: { only_integer: true, greater_than: 0, less_than: 32, allow_nil: true }
    validates :month, numericality: { only_integer: true, greater_than: 0, less_than: 13, allow_nil: true }
    validates :year, format: { with: /\A\d{4}\z/, allow_nil: true }
  end
end

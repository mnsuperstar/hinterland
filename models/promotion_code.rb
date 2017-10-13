# == Schema Information
#
# Table name: promotion_codes
#
#  id                :integer          not null, primary key
#  name              :string           not null
#  description       :text
#  code              :string           not null
#  limit             :integer
#  amount_cents      :integer
#  amount_percentage :decimal(4, 1)
#  valid_from        :datetime
#  valid_until       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class PromotionCode < ApplicationRecord
  include HasApi

  MIN_PERCENT = 0.1
  MAX_PERCENT = 100

  monetize :amount_cents, allow_nil: true

  validates :amount_percentage,
            numericality: {
              greater_than_or_equal_to: MIN_PERCENT,
              less_than_or_equal_to: MAX_PERCENT, allow_nil: true
            }
  validates :amount_cents, numericality: { only_integer: true, allow_nil: true }
  validates :code, presence: true, uniqueness: true
  validate :value_presence

  has_many :bookings, dependent: :nullify

  before_validation :ensure_code

  def self.find_valid_by_code(code)
    valid.find_by(code: code)
  end

  def self.valid
    joins('LEFT JOIN bookings ON bookings.promotion_code_id = promotion_codes.id')
      .group('promotion_codes.id')
      .having('promotion_codes.limit IS NULL OR promotion_codes.limit > COUNT(bookings.id)')
      .where('valid_from IS NULL OR valid_from <= ?', DateTime.now)
      .where('valid_until IS NULL OR valid_until >= ?', DateTime.now)
  end

  def self.api_attributes
    %i(code name description amount amount_percentage promotion_value )
  end

  def used_by? user
    bookings.pending_or_accepted.where(adventurer: user).exists?
  end

  def promotion_value
    if amount_percentage.present?
      "#{amount_percentage}%"
    else
      amount_cents.present? ? amount.format : nil
    end
  end

  def count_discount(total)
    if amount_percentage.present?
      discount = (amount_percentage * total / BigDecimal.new(100))
      discount > total ? total : discount
    else
      amount_cents.present? ? [amount, total].min : 0
    end
  end

  private

  def ensure_code
    self.code = code.presence || generate_code
  end

  def generate_code
    loop do
      code = SecureRandom.hex(6)
      break code unless PromotionCode.find_by(code: code)
    end
  end

  def value_presence
    errors.add(:amount, :blank, alt_attribute: PromotionCode.human_attribute_name(:amount_percentage)) if amount.blank? && amount_percentage.blank?
  end
end

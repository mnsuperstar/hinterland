# == Schema Information
#
# Table name: bookings
#
#  id                       :integer          not null, primary key
#  uid                      :string
#  booking_number           :string
#  start_on                 :date             not null
#  end_on                   :date             not null
#  number_of_adventurers    :integer
#  adventure_id             :integer
#  promotion_code_id        :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  adventurer_id            :integer
#  guide_id                 :integer
#  total_price_cents        :integer          default(0), not null
#  total_price_currency     :string           default("USD"), not null
#  card_id                  :integer
#  status                   :integer          default("pending")
#  accepted_at              :datetime
#  tax_cents                :integer          default(0), not null
#  tax_currency             :string           default("USD"), not null
#  sub_total_price_cents    :integer          default(0), not null
#  sub_total_price_currency :string           default("USD"), not null
#  itinerary_recipients     :string           default([]), is an Array
#  discount_cents           :integer          default(0), not null
#  discount_currency        :string           default("USD"), not null
#  credit_amount_cents      :integer          default(0), not null
#  credit_amount_currency   :string           default("USD"), not null
#  service_fee_cents        :integer          default(0), not null
#  service_fee_currency     :string           default("USD"), not null
#  total_payout_cents       :integer          default(0), not null
#  total_payout_currency    :string           default("USD"), not null
#  company_id               :integer
#  adventurer_type          :string           default("User")
#

class Booking < ApplicationRecord
  include HasApi
  include HasUid
  include HasNotification
  include HasTax
  include HasCharge
  include CalculatableResponse
  include SlackNotifier
  include HasUserAgent
  include BookingReferralCredit
  include HasCompany

  MINIMUM_STRIPE_AMOUNT = 50

  slack_notify_on :create,
                  action_text: {
                    create: "created a new booking"
                  },
                  object_name: :booking_number

  before_validation :ensure_booking_number, :ensure_company, :ensure_card
  before_validation :calculate_price, if: :price_will_change?
  before_update :ensure_accepted_at
  before_save :ensure_total_payout,
                if: proc{ |booking| booking.service_fee_cents_changed? || booking.total_price_cents_changed? }
  after_update :update_bookings_count,
                 if: proc { |booking| booking.status_changed? }
  after_commit :update_bookings_count, on: [:create, :destroy],
                 if: proc { |booking| booking.accepted? }

  validates :adventurer, :adventure, :start_on, :end_on,
            :number_of_adventurers,
            presence: true
  validates :card, presence: true, unless: :skip_validation_for_availability
  validates :number_of_adventurers, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validate :verified_adventurer, on: :create
  validate :maximum_number_of_adventurers,
           if: proc { |booking|
             booking.adventure_id? && booking.number_of_adventurers?
           }
  validate :ensure_booking_dates, unless: :skip_validation_for_availability
  validate :ensure_adventure_bookable, on: :create
  validate :start_on_the_future
  validate :ensure_unused_promo_code, on: :create

  belongs_to :adventure
  belongs_to :adventurer, polymorphic: true
  belongs_to :guide, class_name: 'User', foreign_key: 'guide_id'
  belongs_to :promotion_code
  belongs_to :card
  has_one    :review, as: :reviewable, dependent: :destroy
  has_one :booking_tip

  scope :past, -> { where('start_on < ?', Date.today) } # on going bookings treated as future
  scope :upcoming, -> { where('start_on >= ?', Date.today) }
  scope :expired, -> { where('created_at = ? AND status = ?', 1.week.ago, Booking.statuses['pending']) }
  scope :responded_quickly, -> { where("accepted_at IS NOT NULL AND accepted_at <= (created_at + '1 day'::interval)") }
  scope :pending_or_accepted, -> { where(status: ['pending', 'accepted']) }
  scope :reviewable, -> {
    joins("LEFT JOIN reviews r_check ON r_check.reviewable_type = 'Booking' AND r_check.reviewable_id = bookings.id")
      .group('bookings.id')
      .having('COUNT(r_check.id) = 0')
      .where('start_on <= ?', Date.today) # Allow past and ongoing
      .accepted.distinct
  }

  enum status: [:pending, :accepted, :rejected, :canceled]
  scope :due_by_tomorrow, -> { where(start_on: 1.day.from_now) }

  monetize :sub_total_price_cents, :total_price_cents, :discount_cents, :service_fee_cents, :total_payout_cents, :disable_validation => true
  delegate :price, :additional_price, :number_of_people_included, :main_activity_title, :location_name,
           :inclusions,
           to: :adventure, prefix: true, allow_nil: true
  delegate :name, :location, :phone_number, :email_alias,:bio, :profile_photo_url, to: :guide, prefix: true, allow_nil: true

  attr_accessor :card_uid, :skip_validation_for_availability

  def self.api_attributes
    %i(uid)
  end

  def self.index_api_attributes
    %i(uid)
  end

  def self.adventurer_api_attributes
    %i(uid booking_number start_on end_on number_of_adventurers
       adventure_price sub_total_price tax discount total_price
       adventure_api_attribute_details guide_api_attribute_details status itinerary_recipients is_reviewable_api_attribute tips)
  end

  def self.adventurer_index_api_attributes
    %i(uid booking_number start_on end_on number_of_adventurers
       adventure_price total_price
       adventure guide_api_attribute status itinerary_recipients)
  end

  def self.guide_api_attributes
    %i(uid booking_number start_on end_on number_of_adventurers
       adventure_price service_fee sub_total_price tax discount credit_amount total_price total_payout
       adventure adventurer_api_attribute status)
  end

  def self.guide_index_api_attributes
    %i(uid booking_number start_on end_on number_of_adventurers
       adventure_price total_payout total_price
       adventure adventurer_api_attribute status)
  end

  def guide_api_attribute
    guide.try(:to_api_data, :guide_nested)
  end

  def guide_api_attribute_details
    guide.try(:to_api_data, :details_guide_nested)
  end

  def adventurer_api_attribute
    adventurer.to_api_data(:adventurer_nested)
  end

  def adventure_api_attribute_details
    adventure.to_api_data(:details_nested)
  end

  def adventure_uid=(uid)
    self.adventure = Adventure.find_by_uid(uid)
  end

  def self.payments
    {
      pending: pending.guide_sum.cents,
      accepted: accepted.guide_sum.cents
    }
  end

  def self.guide_sum
    Money.new(sum(:total_payout_cents))
  end

  def promo_code=(code)
    self.promotion_code = PromotionCode.find_valid_by_code(code)
  end

  def itinerary_recipients= value
    super set_array(value)
  end

  def past?
    start_on < Date.today
  end

  def ongoing?
    start_on == Date.today
  end

  def upcoming?
    start_on >= Date.today
  end

  def total_adventure_dates
    start_on.present? && end_on.present? ? [(end_on - start_on).to_i + 1, 0].max : 0
  end

  def base_price
    price = (adventure_price || Money.new(0))
    price += [number_of_adventurers.to_i - adventure.number_of_people_included, 0].max * adventure.additional_price
    price * total_adventure_dates
  end

  def ensure_total_payout
    self.total_payout = [total_price - service_fee, 0].max
  end

  def update_rating
    adventure.update_rating
  end

  def is_reviewable
    accepted? && (past? || ongoing?) && !review.try(:persisted?)
  end

  def is_reviewable_api_attribute
    is_reviewable && current_user == adventurer
  end

  private

  def tips
    return unless booking_tip
    booking_tip.tips
  end

  def start_on_the_future
    if start_on && past?
      new_record? ?
        errors.add(:start_on, :past_date) :
        errors.add(:base, :past_booking)
    end
  end

  def ensure_unused_promo_code
    if promotion_code && adventurer && promotion_code.used_by?(adventurer)
      errors.add(:promotion_code, :used)
    end
  end

  def calculate_fee
    (base_price * (AppSetting['charge.fee_percents'] || BigDecimal.new(0)) / 100).round
  end

  def ensure_accepted_at
    self.accepted_at = Time.zone.now unless pending?
  end

  def ensure_card
    self.card = adventurer.cards.find_by(uid: card_uid) if card_uid
  end

  def ensure_company
    self.company = adventure.try(:company)
  end

  def ensure_booking_number
    if booking_number.blank?
      length = 4
      loop do
        self.booking_number = SecureRandom.hex(length).upcase
        break unless Booking.find_by(booking_number: booking_number)
        length += 1
      end
    end
  end

  def price_will_change?
    adventure && adventurer &&
      ( adventure_id_changed? ||
        start_on_changed? || end_on_changed? ||
        number_of_adventurers_changed? ||
        promotion_code_id_changed? )
  end

  def calculate_price
    self.service_fee = calculate_fee
    self.sub_total_price = base_price
    self.discount = promotion_code.count_discount(sub_total_price) if promotion_code
    ensure_tax
    self.total_price = sub_total_price - discount + tax
    self.credit_amount = [self.total_price, adventurer.credit_amount].min
    self.total_price -= credit_amount
    if total_price.cents < MINIMUM_STRIPE_AMOUNT
      self.discount += total_price
      self.total_price = Money.new(0)
    end
  end

  def ensure_booking_dates
    return if start_on.nil? || end_on.nil?

    if (!changed.include?('status') || accepted?) && adventure && !adventure.include_date?(start_on, end_on)
      errors.add(:base, :date_not_available)
    elsif total_adventure_dates <= 0
      errors.add(:base, :date_invalid)
    end
  end

  def verified_adventurer
     if AppSetting['adventurer.skip_verification']
      errors.add(:adventurer, :required) if adventurer && !adventurer.adventurer?
    else
      errors.add(:adventurer, :unverified) if adventurer && !adventurer.is_verified_adventurer
    end
  end

  def maximum_number_of_adventurers
    if number_of_adventurers > adventure.group_size
      errors.add(:number_of_adventurers, :less_than_or_equal_to, count: (adventure.group_size))
    end
  end

  def ensure_adventure_bookable
    errors.add(:adventure, :unlisted) if adventure && !adventure.is_listed
    errors.add(:company, :without_stripe_account) if company && !company.has_bank_account?
  end

  def update_bookings_count
    adventure.update_bookings_count
  end

  def set_array value
    value.is_a?(String) ?
      value.split(/,|\n/).map(&:strip) :
      value
  end
end

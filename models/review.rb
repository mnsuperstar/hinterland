# == Schema Information
#
# Table name: reviews
#
#  id              :integer          not null, primary key
#  reviewable_id   :integer
#  text            :text
#  rating          :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  reviewable_type :string
#  uid             :string
#  reviewer_id     :integer
#  title           :string
#  company_id      :integer
#

class Review < ApplicationRecord
  include HasApi
  include HasUid
  include HasCompany

  belongs_to :reviewer, class_name: 'User'
  belongs_to :reviewable, polymorphic: true

  validates :reviewer, presence: true
  validates :reviewer_id, uniqueness: { scope: [:reviewable_id, :reviewable_type] }
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  validates :text, length: { maximum: 1000 }
  validates :title, length: { maximum: 100 }
  validate :reviewable_presence
  validate :adventure_reviewable, if: -> (review) { review.reviewable_type == 'Adventure' }
  validate :booking_reviewable, if: -> (review) { review.reviewable_type == 'Booking' }

  after_commit :calculate_reviewable_rating

  delegate :uid, to: :reviewable, prefix: true, allow_nil: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def self.api_attributes
    %i(uid reviewer reviewable_uid reviewable_type rating title text created_at)
  end

  def self.nested_api_attributes
    super - %i(reviewer) # prevent endless loop
  end

  def reviewable_type_api_attribute
    reviewable_type == 'UsersRole' ?
      reviewable.role_name.classify :
      reviewable_type
  end

  def adventure_uid
    reviewable_type == 'Adventure' ? reviewable.uid :
      reviewable_type == 'Booking' ? reviewable.adventure.try(:uid) :
      nil
  end

  def adventure_uid= value
    adventure = Adventure.find_by_uid(value)
    if adventure
      self.reviewable = booking = adventure.bookings.reviewable.order(:accepted_at).first
      self.reviewable_type = 'Adventure' if booking.nil?
      booking
    else
      self.reviewable = nil
    end
  end

  def booking_uid
    reviewable_type == 'Booking' ? reviewable.uid : nil
  end

  def booking_uid= value
    self.reviewable = Booking.find_by_uid(value)
  end

  def guide_uid
    reviewable_type == 'UsersRole' && reviewable.role_name == 'guide' ? reviewable.uid : nil
  end

  def guide_uid= value
    self.reviewable = UsersRole.find_by_user_uid_and_role_name(value, 'guide')
  end

  def adventurer_uid
    reviewable_type == 'UsersRole' && reviewable.role_name == 'adventurer' ? reviewable.uid : nil
  end

  def adventurer_uid= value
    self.reviewable = UsersRole.find_by_user_uid_and_role_name(value, 'adventurer')
  end

  private

  def adventure_reviewable
    errors.add(:reviewable, :unreviewable) if reviewable.nil?
  end

  def booking_reviewable
    errors.add(:reviewable, :unreviewable) if !reviewable.is_reviewable || reviewable.adventurer != reviewer
  end

  def reviewable_presence
    errors.add(:reviewable, :blank) if !reviewable_type.in?(%w(Adventure Booking)) && reviewable.blank?
  end

  def calculate_reviewable_rating
    ReviewableRatingJob.perform_later(reviewable)
  end
end

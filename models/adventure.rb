# == Schema Information
#
# Table name: adventures
#
#  id                        :integer          not null, primary key
#  uid                       :string
#  title                     :string
#  description               :text
#  reviews_count             :integer          default(0), not null
#  reviews_average_rating    :decimal(2, 1)
#  rundowns                  :string           default([]), is an Array
#  inclusions                :string           default([]), is an Array
#  is_featured               :boolean          default(FALSE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  price_cents               :integer          default(0), not null
#  price_currency            :string           default("USD"), not null
#  location_id               :integer
#  location_note             :string
#  difficulty                :integer          default("beginner"), not null
#  location_name             :string
#  group_size                :integer
#  duration                  :integer
#  notes                     :text
#  is_listed                 :boolean          default(TRUE)
#  bookings_count            :integer          default(0)
#  slug                      :string
#  position                  :integer
#  short_uid                 :string           not null
#  additional_price_cents    :integer          default(0), not null
#  additional_price_currency :string           default("USD"), not null
#  number_of_people_included :integer          default(3), not null
#  preparations              :string           default([]), is an Array
#  is_draft                  :boolean          default(FALSE)
#  last_edited_attribute     :string
#  company_id                :integer
#

class Adventure < ApplicationRecord
  include FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include SlackNotifier
  slack_notify_on :create,
                  action_text: {
                    create: "created a new adventure"
                  },
                  object_name: :title

  enum difficulty: [ :beginner, :intermediate, :advanced ]
  enum duration: [:half, :full]

  include SearchableAdventure
  include Reviewable
  include HasUid
  include HasApi
  include HasCompany

  monetize :price_cents, :additional_price_cents

  acts_as_list

  after_update :update_adventure_count,
                 if: proc { |adventure| (adventure.is_listed_changed? || adventure.company_id_changed?) && !is_draft }
  after_commit :update_adventure_count, on: [:create, :destroy], unless: :is_draft
  after_commit :record_track, on: :create

  belongs_to :location

  has_many :adventures_activities, dependent: :destroy
  has_many :activities, through: :adventures_activities
  has_many :adventure_images, -> { ordered }, dependent: :destroy, inverse_of: :adventure
  has_many :adventure_dates, -> { order(start_on: :asc, end_on: :asc, id: :asc) }, dependent: :destroy, inverse_of: :adventure
  has_many :bookings, dependent: :destroy
  has_many :booking_reviews, through: :bookings, source: 'review'
  has_many :adventures_users, dependent: :destroy
  has_many :adventures_guides_assignments, dependent: :destroy
  has_many :guides, through: :adventures_guides_assignments
  has_many :favoriting_users,through: :adventures_users, source: :user
  has_many :pre_booking_urls, dependent: :destroy

  accepts_nested_attributes_for :adventure_images, :adventure_dates, allow_destroy: true

  scope :featured, -> { where(is_featured: true) }
  scope :listed, -> { includes(:adventures_guides_assignments).where(is_listed: true).where.not(adventures_guides_assignments: { adventure_id: nil }) }
  scope :with_guide_uid, -> (guide_uid) {joins(:guides).where('users.uid = ?', guide_uid)}

  delegate :latitude, :longitude, to: :location, prefix: false, allow_nil: true
  delegate :name, :profile_photo, to: :guide, prefix: true, allow_nil: true

  attr_accessor :images, :skip_ensure_editable, :tracker

  validates :title, :price, :location, :difficulty, :group_size, :duration, :activities, presence: true, unless: :is_draft
  validates :group_size, numericality: { greater_than: 0, less_than_or_equal_to: 16 }, unless: :is_draft
  validates :title, length: { maximum: 70 }, unless: :is_draft
  validates :notes, length: { maximum: 2000 }, unless: :is_draft
  validate :ensure_editable, on: :update, unless: :skip_ensure_editable

  before_create :unlist_params, unless: -> (a) { a.company.try(:can_list_adventure?) }
  before_validation :ensure_draft, on: :update
  before_validation :unlist_draft
  before_save :ensure_short_uid
  after_commit :notify_location_subscriber, on: [:create], if: :is_listed
  after_update :notify_location_subscriber, if: -> (a) { (a.location_id_changed? || a.is_listed_changed?) && a.is_listed && !a.is_draft }
  before_destroy :ensure_removable
  after_update :rerun_create_callback

  def self.api_attributes
    %i(uid slug title description activities guide_api_attribute group_size duration notes preparations
      rundowns inclusions price additional_price number_of_people_included location_name location_note location difficulty
      reviews_api_attribute adventure_images is_favorite adventure_dates_api_attribute share_url
      duration is_listed_api_attribute)
  end

  def self.index_api_attributes
    %i(uid slug title description activities guide_api_attribute preparations
      rundowns inclusions price additional_price number_of_people_included location_name location_note location
      reviews_api_attribute adventure_images is_favorite adventure_dates_api_attribute share_url duration group_size)
  end

  def self.nested_api_attributes
    %i(uid slug title description activities price additional_price number_of_people_included group_size
       location_name location_note location adventure_images share_url duration is_listed_api_attribute)
  end

  def self.details_nested_api_attributes
    nested_api_attributes + %i(difficulty inclusions reviews_api_attribute_rating)
  end

  def self.guide_draft_api_attributes
    guide_api_attributes << :last_edited_attribute
  end

  def self.guide_api_attributes
    api_attributes + %i(is_listed is_editable is_removable is_draft)
  end

  def reviews
    @reviews ||= Review.joins("LEFT JOIN bookings ON reviews.reviewable_id = bookings.id AND reviews.reviewable_type = 'Booking'")
      .where("bookings.adventure_id = :id OR (reviews.reviewable_id = :id AND reviews.reviewable_type = 'Adventure')", id: id)
      .distinct
  end

  def guide_api_attribute
    guides.to_api_data(:guide_nested)
  end

  def adventure_dates_api_attribute
    dates = Set.new
    adventure_dates.each do |d|
      dates += (d.start_on..d.end_on).to_set
    end
    dates.map do |d|
      {start_on: d, end_on: d}
    end
  end

  def inclusions= value
    super set_array(value)
  end

  def rundowns= value
    super set_array(value)
  end

  def preparations= value
    super set_array(value)
  end

  def is_favorite
    current_user && current_user.id.in?(favoriting_user_ids)
  end

  def activity_uid=(uid)
    self.activities = [Activity.find_by_uid(uid)].compact
  end

  def location_uid=(uid)
    self.location = Location.find_by_uid(uid)
  end

  def dates= dates
    self.adventure_dates = dates.map{ |date| AdventureDate.new(date) }
  end

  def images= imgs
    self.adventure_images = imgs.map{ |img| AdventureImage.new(file: img) }
  end

  def include_date?(start_on, end_on)
    adventure_dates.included_dates(start_on, end_on).present?
  end

  def is_editable
    bookings_count_was.to_i.zero?
  end

  alias_method :is_removable, :is_editable

  def list
    unless is_draft
      self.is_listed = true
      save!(validate: false)
    else
      errors.add(:is_listed, :draft)
      false
    end
  end

  def unlist
    self.is_listed = false
    save!(validate: false)
  end

  def listed?
    !!(is_listed && guides.any?)
  end

  def is_listed_api_attribute
    listed?
  end

  def update_notifiable?
    (created_at == updated_at || updated_at < 1.hour.ago) && !is_draft_was
  end

  def send_update_notification
    guides.each do |guide|
      if guide.email_notification && update_notifiable?
        UserMailer.notify_updated_adventure(guide, self)
                  .deliver_later
      end
    end
  end

  def update_bookings_count
    return if destroyed?
    update_column :bookings_count, bookings.accepted.count
  end

  def main_activity
    activities.first
  end

  def main_activity_title
    activities.first.title
  end


  def main_image
    adventure_images.first
  end

  def share_url
    Rails.application.routes.url_helpers.shortened_adventure_url(short_uid, host: ENV['SHORTENER_DOMAIN'])
  end

  def unlist_params
    self.is_listed = false
  end

  def location_name
    super.presence || location.try(:city_state)
  end

  private

  def record_track
    return unless tracker.present?
    tracker.track(tracker.current_user, track_message, adventure_uid: uid)
  end

  def track_message
    is_draft ? 'created an adventure draft' : 'created an adventure'
  end

  def unlist_draft
    unlist_params if is_draft
  end

  def ensure_draft
    if is_draft_changed? && !is_draft_was
      self.is_draft = is_draft_was
    end
  end

  def rerun_create_callback
    if is_draft_changed? and not is_draft
      send_slack_notification action: :create,
                  action_text: {
                    create: "finalized a new adventure"
                  },
                  object_name: :title
    end
  end

  def update_adventure_count
    guides.each do |guide|
      if guide.id_changed?
        User.find_by(id: guide.id_was).try(:update_adventures_count)
      end
      guide.try(:update_adventures_count)
    end
  end

  def slug_candidates
    # using 'try' because of friendly_id generate slug before validation
    [
      [title, location.try(:city), location.try(:state)],
      [title, location.try(:city), location.try(:state), company.try(:name)],
      [title, uid]
    ]
  end

  def set_array value
    value.is_a?(String) ?
      value.split(/,|\n/).map(&:strip) :
      value
  end

  def ensure_editable
    if changed.present? && !is_editable && !is_draft
      errors.add(:base, :not_editable)
    end
  end

  def ensure_removable
    unless is_removable
      errors.add(:base, :not_removable)
      raise ActiveRecord::Rollback
    end
  end

  def notify_location_subscriber
    NotifyLocationSubscriberJob.perform_later(self)
  end

  def ensure_short_uid
    self.short_uid = generate_short_uid if short_uid.blank?
  end

  def generate_short_uid
    length = 4
    loop do
      uid = SecureRandom.urlsafe_base64(length).downcase
      break uid unless Adventure.exists?(short_uid: uid)
      length += 1
    end
  end
end

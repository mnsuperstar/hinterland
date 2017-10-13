module AsGuide
  extend ActiveSupport::Concern

  included do
    scope :guides, -> {where(roles: {name: 'guide'}).joins(:roles)}
    scope :featured, -> { joins(:users_roles).where(users_roles: { is_featured: true }).distinct }
    scope :featured_guides, -> { guides.featured }
    scope :verified_guides, -> { guides.where(users_roles: { is_verified: true }) }
    scope :unverified_guides, -> { guides.where(users_roles: { is_verified: false }) }
    scope :has_valid_ach, -> { guides.joins(:stripe_account).where.not(stripe_accounts: { address_postal_code: nil }) }
    scope :has_invalid_ach, -> {
      guides.joins("LEFT JOIN stripe_accounts ON stripe_accounts.user_id = users.id")
        .where(stripe_accounts: { address_postal_code: nil })
    }
    scope :need_ach_reminder, -> {
      has_invalid_ach
        .where('reminded_at <= :time OR (reminded_at IS NULL AND users.created_at <= :time)', {time: 7.days.ago.end_of_day})
    }

    validates :bio, presence: { if: :guide? }

    has_many :certifications, dependent: :destroy, inverse_of: :user # adding inverse of so user presence validation works
    # has_many :adventures, -> { order(position: :asc, id: :desc) }, dependent: :nullify
    has_many :adventures, through: :adventures_guides_assignments
    has_many :received_bookings, class_name: 'Booking', foreign_key: "guide_id", dependent: :nullify
    has_many :withdraws, dependent: :destroy
    has_many :adventures_guides_assignments, dependent: :destroy
    has_one :stripe_account, dependent: :destroy

    attr_writer :is_verified_guide
    enum past_guides_count: %w(0 1-10 10-20 20+)

    after_save :update_is_verified_guide
    after_save do
      adventures.each do |adventure|
        adventure.schedule_indexing('update')
      end if first_name_changed? || last_name_changed?
    end
  end

  module ClassMethods
    def guide_api_attributes
      api_attributes +
        %i(has_guide_experience has_guide_certifications response_rate
           certifications_api_attribute is_verified_guide phone_number_api_attribute_guide
           adventures past_trips_count activities email_api_attribute_alias adventures_count slug has_ach)
    end

    def guide_index_api_attributes
      index_api_attributes +
        %i(has_guide_experience has_guide_certifications response_rate
           certifications_api_attribute is_verified_guide
           adventures past_trips_count activities email_api_attribute_alias slug has_ach)
    end

    def guide_public_api_attributes
      %i(uid short_name slug)
    end

    def guide_nested_api_attributes
      %i(uid email_api_attribute_alias first_name short_name shortened_last_name user_type
         bio location profile_photo reviews_api_attribute slug)
    end

    def details_guide_nested_api_attributes
      guide_nested_api_attributes + %i(activities)
    end

    def with_guide_phone_number
      return all if current_user.nil?
      joins("LEFT JOIN bookings g_p_c_bookings ON g_p_c_bookings.guide_id = users.id AND g_p_c_bookings.status = #{Booking.statuses[:accepted]} AND g_p_c_bookings.adventurer_id = #{current_user.id}")
        .select('users.*')
        .select('(CASE WHEN COUNT(g_p_c_bookings.id) > 0 THEN users.phone_number ELSE NULL END) AS guide_phone_number')
        .group("users.id")
    end
  end

  def received_booking_from adventurer
    received_bookings.find_by adventurer: adventurer
  end

  def guide?
    has_role? 'guide'
  end

  def featured?
    is_featured_guide
  end

  def has_guide_certifications
    certifications.any?
  end

  def certifications_api_attribute
    certifications.validated.pluck(:name)
  end

  def has_guide_experience
    !past_guides_count.to_i.zero?
  end

  def is_verified_guide
    users_role_for('guide').try(:is_verified)
  end

  def is_featured_guide
    users_role_for('guide').is_featured
  end

  def past_trips_count
    received_bookings.accepted.past.count
  end

  def has_bank_account?
    stripe_account.try(:address_postal_code).present?
  end

  def phone_number_api_attribute_guide
    self[:guide_phone_number].try(:phony_formatted, format: :international)
  end

  def has_ach
    has_valid_ach?
  end

  def update_adventures_count
    return if destroyed?
    update_column :adventures_count, adventures.listed.count
  end

  def adventures_count
    super.presence || adventures.listed.count
  end

  def can_list_adventure?
    is_verified_guide && has_ach
  end

  alias_method :has_valid_ach?, :has_bank_account?

  private

  def update_is_verified_guide
    unless @is_verified_guide.nil?
      users_role_for('guide').try(:update_column, :is_verified, @is_verified_guide)
      schedule_guide_on_boarding_reminder if @is_verified_guide
    end
  end

  def rated_chats(upto: 30.days.ago, limit: nil)
    r = chats
      .with_messages
      .where(created_at: upto..24.hours.ago)
      .not_initiated_by(self)
    # exclude chat with blocked / blocking users
    if blocker_or_blockee_ids.present?
      r = r.joins("LEFT JOIN user_chats buc ON buc.chat_id = chats.id AND buc.user_id IN (#{blocker_or_blockee_ids.join(',')})")
        .where('buc.id IS NULL')
    end
    limit ? r.limit(limit) : r
  end

  def rated_bookings
    received_bookings
      .where(created_at: 30.days.ago..24.hours.ago)
      .where.not(accepted_at: nil)
  end

  def chat_response_rate
    e_chats = rated_chats
    # get 10 most recent chats from the past 90 days if less than 10 found in since the last 30 days
    e_chats = rated_chats(upto: 90.days.ago, limit: 10).reorder(created_at: :desc) if e_chats.count < 10
    e_count = e_chats.count
    return BigDecimal.new(100) if e_count.zero?
    e_chats.responded_quickly.count / BigDecimal.new(e_count) * 100
  end

  def booking_response_rate
    e_bookings = rated_bookings
    e_count = e_bookings.count
    return BigDecimal.new(100) if e_count.zero?
    e_bookings.responded_quickly.count / BigDecimal.new(e_count) * 100
  end

  def update_response_rate
    update_column :response_rate, (chat_response_rate + booking_response_rate) / BigDecimal.new(2)
  end

  def schedule_guide_on_boarding_reminder
    NotifyGuideAdventureJob.set(wait_until: 2.days.from_now).perform_later(self)
  end
end

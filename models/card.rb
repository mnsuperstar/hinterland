# == Schema Information
#
# Table name: cards
#
#  id                  :integer          not null, primary key
#  uid                 :string           not null
#  stripe_id           :string
#  last4               :string
#  brand               :string
#  is_primary          :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  tokenization_method :string
#  owner_id            :integer
#  owner_type          :string
#

class Card < ApplicationRecord
  include HasUid
  include HasApi

  before_create :create_stripe_card
  before_destroy :delete_stripe_card
  after_save :ensure_primary_card
  after_commit :notify_update, on: [:create, :update]

  belongs_to :owner, polymorphic: true
  has_many :bookings, dependent: :nullify
  has_many :booking_tips, dependent: :nullify

  default_scope { order(created_at: :desc) }
  scope :other_primary_cards,
        -> (self_id) { where(is_primary: true).where.not(id: self_id) }

  attr_accessor :token

  def self.api_attributes
    %i(uid last4 brand is_primary tokenization_method)
  end

  def self.self_api_attributes
    api_attributes
  end

  def apple_pay?
    tokenization_method == 'apple_pay'
  end

  private

  def ensure_user_stripe_customer
    owner.create_stripe_customer! if owner.stripe_customer_id.blank?
  end

  def create_stripe_card
    ensure_user_stripe_customer
    assign_attributes_value
  end

  def card
    @card ||= customer.sources.create(source: token)
  end

  def customer
    @customer ||= Stripe::Customer.retrieve(owner.stripe_customer_id)
  end

  def assign_attributes_value
    self.stripe_id = card.id
    self.last4 = card.dynamic_last4 || card.last4
    self.brand = card.brand
    self.tokenization_method = card.tokenization_method
  end

  def delete_stripe_card
    if has_pending_booking?
      errors.add(:bookings, :pending)
      throw(:abort)
    else
      customer.sources.retrieve(stripe_id).delete
      true
    end
  end

  def has_pending_booking?
    bookings.pending.any?
  end

  def ensure_primary_card
    owner.cards.other_primary_cards(id).update_all(is_primary: false)
  end

  def notify_update
    UserMailer.notify_updated_payment_method(owner).deliver_later if  owner_type == 'User' && owner.email_notification
  end
end

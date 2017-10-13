# == Schema Information
#
# Table name: activities
#
#  id         :integer          not null, primary key
#  uid        :string           not null
#  title      :string
#  thumbnail  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :integer
#  is_hidden  :boolean          default(TRUE)
#  background :string
#

class Activity < ApplicationRecord
  include HasUid
  include HasApi

  mount_uploader :thumbnail, ImageUploader
  mount_uploader :background, ImageUploader

  has_many :user_activities, dependent: :destroy
  has_many :users, through: :user_activities

  has_many :adventures_activities, dependent: :destroy
  has_many :adventures, through: :adventures_activities

  has_many :children, class_name: "Activity",
    foreign_key: "parent_id", dependent: :restrict_with_error

  belongs_to :parent, class_name: "Activity"

  scope :roots, -> { where(parent_id: nil) }
  scope :leafs, -> { joins('LEFT JOIN activities children_activities ON activities.id = children_activities.parent_id').where('children_activities.id IS NULL') }

  scope :visible, -> { where(is_hidden: false) }
  scope :hidden, -> { where(is_hidden: true) }

  delegate :uid, to: :parent, prefix: true, allow_nil: true

  def self.api_attributes
    %i(uid title thumbnail background parent_uid child_uids)
  end

  def self.nested_api_attributes
    %i(uid title thumbnail)
  end

  def self.options_for_multi_select options = {}
    options.reverse_merge!(padding: '-', level: 0)
    all.inject([]) do |arr, a|
      arr +
        [["#{options[:padding] * options[:level]}#{a.title}", a.id]] +
        a.children.options_for_multi_select(options.merge(level: options[:level] + 1))
    end
  end

  def child_uids
    children.visible.pluck(:uid)
  end
end

# == Schema Information
#
# Table name: adventure_dates
#
#  id           :integer          not null, primary key
#  start_on     :date             not null
#  end_on       :date
#  adventure_id :integer
#

class AdventureDate < ApplicationRecord
  include HasApi

  belongs_to :adventure
  scope :included_dates, -> (start_on, end_on){where('start_on <=  ? and end_on >= ?', start_on, end_on)}
  validate :overlap

  validates :start_on, :end_on, :adventure, presence: true

  after_save do
    adventure.schedule_indexing('update') if (start_on_changed? || end_on_changed?) && !adventure.transaction_record_state(:new_record)
  end

  def self.api_attributes
    %i(start_on end_on)
  end

  %w(start_on end_on).each do |attr|
    define_method("#{attr}=") do |value|
      begin
        super value.is_a?(String) ? Date.parse(value) : value
      rescue ArgumentError => e
        unless e.message == 'invalid date'
          raise
        end
      end
    end
  end

  private

  def overlap
    return if start_on.nil? || end_on.nil?
    errors.add(:start_on, :overlap) if start_on > end_on
  end
end

# == Schema Information
#
# Table name: app_settings
#
#  id         :integer          not null, primary key
#  name       :string
#  value      :text
#  value_type :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AppSetting < ApplicationRecord
  VALUE_TYPES = %w(integer decimal time string)
  TIME_DENOMINATIONS = %w(second minute hour day week month year)
  serialize :value

  validates :name, :value_type, presence: true
  validates :name, uniqueness: true

  before_validation :set_value_type

  def self.value_type_for value
    if value.is_a? ActiveSupport::Duration
      'time'
    elsif value.in? [true, false, 'true', 'false']
      'boolean'
    else
      case value.to_s
      when /\A[-+]?\d+\z/
        'integer'
      when /\A[-+]?\d+(?:\.\d{0,})?\z/
        'decimal'
      when /\A[-+]?\d+(?:\.\d{0,})?\s+(#{TIME_DENOMINATIONS.join('|')})s?\z/i
        'time'
      else
        'string'
      end
    end
  end

  def self.converted_value_for value, value_type
    case value_type
    when 'integer'
      value.to_i
    when 'decimal'
      BigDecimal.new(value, 5)
    when 'time'
      nominal, denomination = value.to_s.split(' ')
      denomination = denomination.try(:sub, /s\z/, '').presence_in(TIME_DENOMINATIONS) || TIME_DENOMINATIONS.first
      nominal = denomination.in?(%w(month year)) ? nominal.to_i : nominal.to_f # unable to use fractional value for month and year
      nominal.send(denomination)
    when 'boolean'
      value.in?([true, 'true']) ? '1' : '0'
    else
      value
    end
  end

  def value
    value_type == 'boolean' ? super == '1' : super
  end

  def value_for_input
    value_type == 'decimal' ? value.to_s : value.inspect
  end

  def self.[] name
    find_by(name: name).try(:value)
  end

  def self.[]= name, value
    app_setting = where(name: name).first_or_initialize
    app_setting.update(value: value, value_type: nil)
  end

  private

  def set_value_type
    self.value_type = value_type.presence_in(VALUE_TYPES) || self.class.value_type_for(value)
    self.value = self.class.converted_value_for self[:value], value_type
  end
end

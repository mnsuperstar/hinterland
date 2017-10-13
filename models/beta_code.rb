# == Schema Information
#
# Table name: beta_codes
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  description :text
#  code        :string           not null
#  limit       :integer
#  valid_from  :datetime
#  valid_until :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class BetaCode < ApplicationRecord
  validates :code, presence: true, uniqueness: true

  before_validation :ensure_code

  def self.find_valid_by_code(code)
    valid.find_by(code: code)
  end

  def self.valid
    where('beta_codes.limit IS NULL OR beta_codes.limit > 0')
      .where('valid_from IS NULL OR valid_from <= ?', DateTime.now)
      .where('valid_until IS NULL OR valid_until >= ?', DateTime.now)
  end

  def update_limit
    update_column(:limit, limit-1) if limit
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
end

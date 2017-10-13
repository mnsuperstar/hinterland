# == Schema Information
#
# Table name: admin_companies
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  company_id             :integer
#  auth_token             :string
#  uid                    :string           not null
#  locked_at              :datetime
#  unlock_token           :string
#  name                   :string
#

class AdminCompany < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  include HasCompany
  include HasApi
  include HasUid

  before_create :ensure_auth_token

  def self.api_attributes
    %i(uid email name)
  end

  def self.auth_api_attributes
    api_attributes + %i(auth_token_api_attribute)
  end

  def auth_token_api_attribute
    "#{uid}.#{auth_token}" if auth_token.present?
  end

  def ensure_auth_token
    self.auth_token = generate_auth_token if auth_token.blank?
  end

  def ensure_auth_token!
    ensure_auth_token && save!
  end

  private

  def generate_auth_token
    loop do
      token = Devise.friendly_token
      break token unless AdminCompany.where(auth_token: token).exists?
    end
  end
end

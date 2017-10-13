# == Schema Information
#
# Table name: contacts
#
#  id         :integer          not null, primary key
#  full_name  :string
#  email      :string
#  phone      :string
#  company    :string
#  message    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Contact < ApplicationRecord
  validates :full_name, :email, :phone, :company, :message,
            presence: true
  validates :email, format: { with: Devise.email_regexp }, allow_blank: true
  validates :full_name, :email, :phone, :company,
            length: { maximum: 250 }
  after_commit :send_email, on: [:create]

  def self.recipient_email
    ENV.fetch('CONTACT_EMAIL', 'all@gohinterlands.com')
  end

  private

  def send_email
    AdminMailer.new_contact_us(self).deliver_later
  end
end

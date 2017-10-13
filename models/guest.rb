# == Schema Information
#
# Table name: guests
#
#  id           :integer          not null, primary key
#  email        :string           not null
#  first_name   :string
#  last_name    :string
#  phone_number :string
#  company_id   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Guest < ApplicationRecord
  belongs_to :company
  has_one :card, as: :owner, dependent: :destroy
  has_one :booking, as: :adventurer, dependent: :destroy
end

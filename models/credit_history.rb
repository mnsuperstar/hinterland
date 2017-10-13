# == Schema Information
#
# Table name: credit_histories
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  source_type     :string
#  source_id       :integer
#  reason          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  amount_cents    :integer          default(0), not null
#  amount_currency :string           default("USD"), not null
#

class CreditHistory < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true
  monetize :amount_cents
end

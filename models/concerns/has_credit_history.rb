module HasCreditHistory
  extend ActiveSupport::Concern
  included do
    has_many :credit_histories, dependent: :destroy
    monetize :credit_amount_cents, numericality: {
      greater_than_or_equal_to: 0
    }
  end

  def add_credit_amount! amount, source: nil, reason: nil
    update! credit_amount: (credit_amount + amount)
    credit_histories.create!(source: source,
                             amount: amount,
                             reason: reason)
  end
end

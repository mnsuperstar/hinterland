module HinStripe
  class ExternalAccount < Base
    define_attributes :object, :country, :currency, :routing_number, :account_number

    validates :object, :country, :currency, :routing_number, :account_number, presence: true
    validates :routing_number, length: { is: 9 }

    # lock to bank_account https://stripe.com/docs/api/ruby#update_account-external_account-object
    def object
      'bank_account'
    end

    # lock to usd and US https://github.com/hinterlands/seekers-web/issues/47#issuecomment-190171803
    def currency
      'usd'
    end

    def country
      'US'
    end
  end
end

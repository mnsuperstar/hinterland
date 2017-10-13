module HinStripe
  class Address < Base
    define_attributes :city, :country, :line1, :line2, :postal_code, :state

    validates :line1, :postal_code, :country, :city, :state, presence: true
    validates :country, length: { is: 2 }
  end
end

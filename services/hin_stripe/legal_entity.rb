module HinStripe
  class LegalEntity < Base
    define_attributes :first_name, :last_name, :business_name, :type, :personal_id_number, :business_tax_id
    attr_accessor :personal_id_number_provided, :business_tax_id_provided
    define_association :dob, DateOfBirth
    define_association :address, Address

    validates :dob, :address, :first_name, :type, presence: true
    validates :personal_id_number, presence: true, unless: :personal_id_number_provided
    validates :business_name, presence: true, if: -> (e) { e.type == 'company' }
    validates :business_tax_id, presence: true, if: -> (e) { e.type == 'company' || e.business_tax_id_provided }
    validates :type, inclusion: { in: %w(individual company), allow_nil: true }
    validate_association :dob, :address
  end
end

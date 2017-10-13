module HinStripe
  class Account < Base
    define_attributes :managed, :email, :id

    define_association :tos_acceptance, TosAcceptance
    define_association :external_account, ExternalAccount
    define_association :legal_entity, LegalEntity

    validates :managed, :email, :tos_acceptance, :legal_entity, presence: true
    validate_association :tos_acceptance, :legal_entity
    validate :external_account_validity

    # lock to managed: true
    def managed
      true
    end

    def stripe_account
      @stripe_account
    end

    def stripe_account= value
      if value.is_a?(::Stripe::Account)
        value_hash = value.to_hash
        self.class.attr_names.each do |a|
          v = if a == :external_account
                value_hash[:external_accounts][:data][0]
              else
                value_hash[a]
              end
          send("#{a}=", v)
        end
        nested_changes_applied
      end
      @stripe_account = value
    end

    def new_record?
      id.blank?
    end

    def publishable_key
      stripe_account.keys.publishable
    end

    def secret_key
      stripe_account.keys.secret
    end

    def verified
      stripe_account.verification.disabled_reason.nil?
    end

    def bank_account
      stripe_account.external_accounts.detect{|a| a.object == 'bank_account' }
    end

    def bank_account_last4
      bank_account.try(:last4)
    end

    delegate :charges_enabled, :transfers_enabled, to: :stripe_account, allow_nil: true

    def save
      return false if invalid?
      if stripe_account
        update_stripe_account(self, stripe_account)
        self.stripe_account = stripe_account.save
      else
        self.stripe_account = ::Stripe::Account.create(self.attributes)
      end
    rescue ::Stripe::InvalidRequestError => e
      errors.add(:base, e.message)
      false
    end

    def self.find id
      new.tap{|a| a.stripe_account = ::Stripe::Account.retrieve(id) }
    rescue ::Stripe::AuthenticationError
      raise ::ActiveRecord::RecordNotFound
    end

    private

    def update_stripe_account model, stripe_account
      model.changes.each do |k, v|
        v = v.last
        if k == 'external_account'
          stripe_account.external_account = model.external_account if model[:external_account].valid?
        elsif k == 'id'
          next
        elsif k == 'legal_entity'
          update_stripe_account(model.instance_variable_get("@#{k}"), stripe_account.send(k))
        elsif v.is_a?(Hash)
          stripe_account.send("#{k}=", stripe_account.send(k).as_json.merge(v))
        else
          stripe_account.send("#{k}=", v)
        end
      end
      (model.class.associations - model.changes.keys.map(&:to_sym)).each do |k|
        update_stripe_account(model.instance_variable_get("@#{k}"), stripe_account.send(k)) if instance_variable_get("@#{k}").try(:changed?)
      end
    end

    def external_account_validity
      if !stripe_account || stripe_account.external_accounts.total_count.zero? # no need to validate external_account if it's already exists
        errors.add(:external_account, :blank) if @external_account.blank?
        @external_account.errors.each{|k,v| errors.add("external_account_#{k}", v)} if @external_account.present? && @external_account.invalid?
      end
    end
  end
end

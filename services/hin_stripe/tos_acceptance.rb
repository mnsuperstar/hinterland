module HinStripe
  class TosAcceptance < Base
    define_attributes :date, :ip, :user_agent

    validates :date, presence: true

    def date= value
      @date = value.is_a?(DateTime) || value.is_a?(Time) ? value.to_i : value
    end
  end
end

module HasCompany
  extend ActiveSupport::Concern
  included do
    belongs_to :company

    before_validation :set_company
  end

  private

  def set_company
    self.company ||= current_company
  end
end

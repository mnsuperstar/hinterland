module HasTax
  extend ActiveSupport::Concern

  included do
    monetize :tax_cents
  end

  private

  def tax_available?
    !AvaTax::Configuration.instance.as_json.values.detect(&:blank?) &&
      ENV['AVATAX_COMPANY'].present? &&
      company.try(:has_bank_account?)
  end

  def taxable_amount
    sub_total_price - discount
  end

  def ensure_tax
    return unless tax_available?
    taxSvc = AvaTax::TaxService.new
    getTaxResult = taxSvc.get(getTaxRequest)
    if getTaxResult['ResultCode'] == 'Success'
      self.tax_cents = (BigDecimal.new(getTaxResult["TotalTax"]) * 100).to_i
    else
      error_messages = getTaxResult['Messages'].map{|m| m['Severity'] == 'Error' ? m['Summary'] : nil}.compact
      errors.add(:base, "Tax Error: #{error_messages.join(', ')}")
    end
  end

  def schedule_commit_tax
    return unless tax_available?
    AvataxJob.perform_later('commit_tax', self)
  end

  def commit_tax
    return unless tax_available?
    taxSvc = AvaTax::TaxService.new
    getTaxResult = taxSvc.get(getTaxRequest.merge(:Commit => true, :DocType => 'SalesInvoice'))
    if getTaxResult['ResultCode'] != 'Success'
      error_messages = getTaxResult['Messages'].map{|m| m['Severity'] == 'Error' ? m['Summary'] : nil}.compact
      raise StandardError.new("Tax Error: #{error_messages.join(', ')}")
    end
    result_tax = (BigDecimal.new(getTaxResult["TotalTax"]) * 100).to_i
    if tax_cents != result_tax
      raise StandardError.new("Unexpected non-matching tax in Booking #{id}, #{tax_cents} != #{result_tax}")
    end
  end

  def schedule_cancel_tax
    return unless tax_available?
    AvataxJob.perform_later('cancel_tax', self)
  end

  def cancel_tax
    return unless tax_available?
    taxSvc = AvaTax::TaxService.new
    cancelTaxResult = taxSvc.cancel(cancelTaxRequest)
    if cancelTaxResult['ResultCode'] != 'Success'
      error_messages = cancelTaxResult['Messages'].map{|m| m['Severity'] == 'Error' ? m['Summary'] : nil}.compact
      raise StandardError.new("Tax Error: #{error_messages.join(', ')}")
    end
  end

  def getTaxRequest
    stripe_account = company.stripe_account
    {
      :DocType => 'SalesOrder',
      :Commit => false,
      :DocCode => booking_number,
      :CompanyCode => ENV['AVATAX_COMPANY'],
      :CustomerCode => adventurer.uid,
      :PurchaseOrderNo => booking_number,
      :Addresses => [
                      {
                        :AddressCode => company.uid,
                        :Line1 => stripe_account.address_line1.try(:truncate, 50, omission: '..'),
                        :Line2 => stripe_account.address_line2.try(:truncate, 50, omission: '..'),
                        :City => stripe_account.address_city,
                        :Region => stripe_account.address_state,
                        :Country => stripe_account.address_country,
                        :PostalCode => stripe_account.address_postal_code
                      }
                    ],
      :Lines => [
                   {
                     :LineNo => "1",
                     :ItemCode => booking_number,
                     :Qty => 1,
                     :Amount => taxable_amount,
                     :OriginCode => company.uid,
                     :DestinationCode => company.uid,
                     :Description => "#{number_of_adventurers} people #{total_adventure_dates} days booking for #{adventure.title}"
                   }
                ]
    }
  end

  def cancelTaxRequest
    {
      :DocCode => booking_number,
      :DocType => "SalesInvoice",
      :CancelCode => "DocVoided",
      :CompanyCode => ENV['AVATAX_COMPANY']
    }
  end
end

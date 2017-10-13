module CompanyScoped
  private

  def scoped_resources
    if whitelabel_app?
      super.where(company: @current_company)
    else
      super
    end
  end
end

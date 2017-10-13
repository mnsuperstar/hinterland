class Api::CompaniesController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!

  def create
    @company = Company.new(company_params)
    if @company.save
      render json: { company: @company.to_api_data(:admin) }
    else
      render_error_json @company, status: :unprocessable_entity
    end
  end

  def show
    render_resource @current_company
  end

  private

  def company_params
    params.require(:company)
          .permit(:company, admin_companies_attributes: [:name, :email, :password],
                  cards_attributes: [:token, :is_primary],
                  stripe_subscription_attributes: [:stripe_plan_uid])
  end
end

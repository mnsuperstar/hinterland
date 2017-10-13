class Api::StripeSubscriptionsController < Api::ResourcesController
  include ::CompanyScoped
  skip_before_action :authenticate_user_from_token!, :authenticate_user!
  before_action :authenticate_admin_company_from_token!, :authenticate_admin_company!
  before_action :prepare_stripe_subscription, only: :show

  def create
    @stripe_subscription = current_company.build_stripe_subscription(stripe_subscription_params)
    if @stripe_subscription.save
      render_resource @stripe_subscription
    else
      render_error_json @stripe_subscription, status: :unprocessable_entity
    end
  end

  def show
    render_resource @stripe_subscription
  end

  private

  def stripe_subscription_params
    params.require(:stripe_subscription).permit(:stripe_plan_uid, :company_id)
  end

  def prepare_stripe_subscription
    @stripe_subscription = current_company.stripe_subscription
  end
end

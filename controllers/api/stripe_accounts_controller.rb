class Api::StripeAccountsController < Api::ResourcesController
  include ::CompanyScoped
  before_action :prepare_stripe_account, except: [:create]

  def create
    @stripe_account = current_user.stripe_account || StripeAccount.new(user: current_user)
    update
  end

  def update
    if @stripe_account.update_attributes(stripe_account_params)
      track(current_user, 'added / updated stripe account', stripe_account_uid: @stripe_account.uid)
      render_resource @stripe_account
    else
      render_error_json @stripe_account, status: :unprocessable_entity
    end
  end

  def show
    track(current_user, 'views stripe account', stripe_account_uid: @stripe_account.uid)
    render_resource @stripe_account
  end

  def destroy
    if @stripe_account.destroy
      track(current_user, 'removed stripe account', stripe_account_uid: @stripe_account.uid)
      head :ok
    else
      head :not_acceptable
    end
  end

  private

    def prepare_stripe_account
      @stripe_account = current_user.stripe_account
      raise ActiveRecord::RecordNotFound if @stripe_account.nil?
    end

    def stripe_account_params
      @stripe_account_params = params.require(:stripe_account).permit(
        :tos_accepted,
        external_account: [:account_number, :routing_number],
        legal_entity: [:first_name, :last_name, :business_name, :business_tax_id, :type, :personal_id_number, dob: [:day, :month, :year], address: [:line1, :line2, :postal_code, :city, :state, :country]]
      )
      @stripe_account_params = @stripe_account_params.merge(email: current_user.email,
                                                            tos_acceptance: {
                                                              date: DateTime.now,
                                                              ip: request.remote_ip,
                                                              user_agent: request.user_agent }) if @stripe_account_params[:tos_accepted]
      @stripe_account_params
    end
end

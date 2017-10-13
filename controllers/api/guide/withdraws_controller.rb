class Api::Guide::WithdrawsController < Api::Guide::ResourcesController
  before_action :ensure_verified_guide

  def create
    if new_withdrawal.save
      render_resource(new_withdrawal)
    else
      render_error_json(new_withdrawal, status: :unprocessable_entity)
    end
  end

  def destroy
    if prepared_withdrawal.reverse
      head(:ok)
    else
      render_error_json(prepared_withdrawal, status: :not_acceptable)
    end
  end

  private

  def scoped_resources
    if params[:status].present?
      current_user.withdraws.filter_status(params[:status])
    else
      current_user.withdraws
    end.order(created_at: :desc)
  end

  def new_withdrawal
    @withdrawal ||= current_user.withdraws.new(create_params)
  end

  def prepared_withdrawal
    @withdrawal ||= current_user.withdraws.find_by_uid!(params[:id])
  end

  def create_params
    params.require(:withdraw).permit(:amount_cents).merge(stripe_account: current_user.stripe_account)
  end
end

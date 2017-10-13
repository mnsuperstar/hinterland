class Api::SessionsController < Api::ModuleController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: :create

  def create
    @user = User.find_for_database_authentication(email: user_params[:email])
    if @user && @user.valid_password?(user_params[:password])
      @user.ensure_auth_token
      @user.update_tracked_fields!(request)
      render json: { user: @user.to_api_data(:auth) }
    else
      render_error_json I18n.t('devise.failure.invalid', authentication_keys: User.authentication_keys.join(',')), status: :unauthorized
    end
  end

  def destroy
    # current_user.update_column :auth_token, nil
    head :ok
  end

  private

  def user_params
    @user_params ||= params.require(:user).permit(:email, :password)
  end
end
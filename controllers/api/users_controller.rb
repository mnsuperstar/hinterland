class Api::UsersController < Api::ModuleController
  include ::UserAgentController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!,
                     only: %i(create forgot_password show verify_beta_key)
  before_action :authenticate_user_from_token, only: [:show]

  def create
    @user = User.new(user_params.merge(user_agent))
    if @user.save
      track(@user, "account creation: Email")
      render json: { user: @user.to_api_data(:auth) }
      UserMailer.welcome_email(@user).deliver_later if @user.email_notification
    else
      render_error_json @user, status: :unprocessable_entity
    end
  end

  def show
    if params[:id].present?
      @user = User.find_by_uid!(params[:id])
      track(current_user, "views other's profile", user_uid: @user.uid)
      render json: { user: @user.to_api_data }
    elsif current_user
      track(current_user, 'views their profile')
      render json: { user: current_user.to_api_data(:self) }
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def update
    @user = current_user
    if (password_required = user_params[:password].present?)
      user_params.delete(:current_password) if user_params[:current_password].blank?
    else
      @user_params = user_params.except(:current_password, :password)
    end

    if password_required ? @user.update_with_password(user_params) : @user.update_without_password(user_params)
      track(current_user, 'updates their profile')
      render json: {
        user: @user.to_api_data(:self),
        flash: { message: flash_message('success'), type: 'success' } }
    else
      render_error_json @user, status: :not_acceptable
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error_json e.record, status: :not_acceptable
  end

  def forgot_password
    @user = User.send_reset_password_instructions(forgot_password_user_params)
    track(nil, 'reset their password', email: @user.email)

    if @user || Devise.paranoid
      head :ok
    else
      head :not_found
    end
  end

  def block
    current_user.blockees << User.find_by_uid!(params[:id])
    track(current_user, 'blocks another user', user_uid: params[:id])
  rescue ActiveRecord::RecordNotUnique
    # do nothing on duplicates entry
  ensure
    head :ok
  end

  def unblock
    current_user.blockees.delete User.find_by_uid!(params[:id])
    track(current_user, 'unblocks another user', user_uid: params[:id])
    head :ok
  end

  def verify_beta_key
    beta_code = BetaCode.find_valid_by_code(params[:beta_key])
    if beta_code
      beta_code.update_limit
      head :ok
    else
      render_error_json t('flash.api.beta_code_invalid'), status: :not_acceptable
    end
  end

  private

  def user_params
    @user_params ||= params.require(:user)
                     .permit(:email, :password, :password_confirmation, :current_password,
                             :first_name, :last_name, :user_type, :latitude, :longitude, :bio,
                             :has_guide_experience, :past_guides_count,
                             :gender, :birthdate, :location, :profile_photo, :background_photo, :phone_number,
                             activity_uids: [], certifications_attributes: [:photo],
                             notification_setting_attributes: [:push_notification, :email_notification, :chat_notification])
  end

  def forgot_password_user_params
    params.require(:user).permit(:email)
  end
end

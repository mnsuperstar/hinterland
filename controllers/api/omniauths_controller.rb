class Api::OmniauthsController < Api::ModuleController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: %i(show create)
  before_action :check_auth_token, only: :create

  def create
    case params[:id]
    when 'facebook'
      create_facebook
    else
      head :not_found
    end
  end

  private

  def create_facebook
    fb_user = FbGraph2::User.me(user_params[:oauth][:token])
                            .fetch(fields: [:email, :name, :id, :cover])
    if current_user
      raise FbGraph2::Exception::InvalidRequest, 'Email invalid' unless current_user.email == fb_user.email
    end

    @user = User.find_for_oauth(
              :facebook, user_params.merge(
                uid: fb_user.identifier,
                email: fb_user.email,
                name: fb_user.name,
                photo: {
                  profile_photo: fb_user.picture(:large).url,
                  background_photo: fb_user.cover.try(:source)
                }
              ), current_user
            )

    do_render @user

  rescue FbGraph2::Exception::InvalidRequest, FbGraph2::Exception::InvalidToken => e
    render_error_json e.message, status: :bad_request
  end

  def check_auth_token
    params[:auth_token].present? && !authenticate_user_from_token!
  end

  def user_params
    @user_params ||= params.require(:user).permit(:email, :name,
                      oauth: [:token, :uid, :secret],
                      photo: [:profile_photo, :background_photo,]
                    )
  end

  def do_render(user)
    if user.need_omniauth_confirmation
      render_error_json t('email_existed', scope: %i(flash api omniauth)),
                         status: :conflict
    elsif user.persisted?
      track(@user, "account creation: #{params[:id]}")
      @user.ensure_auth_token
      @user.update_tracked_fields!(request)
      render json: { user: user.to_api_data(:auth) }
    else
      render_error_json user, json: { user: user.to_api_data(:auth) }, status: :unprocessable_entity
    end
  end
end

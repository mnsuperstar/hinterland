class Api::NewslettersController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: :create

  def create
    @newsletter = Newsletter.new(newsletter_params)
    if @newsletter.save
      head :ok
    else
      render_error_json @newsletter, status: :unprocessable_entity
    end
  end

  def newsletter_params
    params.require(:newsletter).permit(:email)
  end
end
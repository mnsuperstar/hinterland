class Api::ActivitiesController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!

  private

  def scoped_resources
    super.visible
  end
end

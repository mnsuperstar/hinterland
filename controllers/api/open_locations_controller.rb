class Api::OpenLocationsController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: [:index]
  before_action :authenticate_user_from_token, only: [:index]
  before_action :paginate_by_default, only: [:index]

  private

  def scoped_resources
    super.order(city: :asc)
  end
end

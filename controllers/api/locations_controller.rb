class Api::LocationsController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: [:index]
  before_action :authenticate_user_from_token, only: [:index]
  before_action :paginate_by_default, only: [:index]

  def reverse_geocode
    render_resource Geocoder.new.reverse_geocode(*params[:id].split(',', 2), create_location: true)
  end

  def available
    track(current_user, "views available locations")
    render_resources Location.available
  end

  private

  def scoped_resources
    if action_name == 'index' && params[:search].present?
      track(current_user, "searches locations", q: params[:search][:text])
      LocationSearch.new(location_search_params).results
    else
      super
    end
  end

  def location_search_params
    params.require(:search).permit(:text)
  end
end

class Api::AdventuresController < Api::ResourcesController
  include ::CompanyScoped
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: [:index, :featured, :by_slug, :filter, :by_short_uid]
  before_action :authenticate_user_from_token, only: [:index, :featured, :by_slug, :filter, :by_short_uid]
  before_action :prepare_adventure, only: [:add_favorite, :remove_favorite]
  before_action :paginate_by_default, only: [:closest]

  alias_method :featured, :index
  alias_method :favorited, :index

  def show
    super
    track_show_event @resource
  end

  def add_favorite
    current_user.adventures_users.create! adventure: @adventure
    render_resource(@adventure,
                    flash: { message: flash_message('success'),
                             type: 'success' })
  rescue ActiveRecord::RecordNotUnique
    # no need to differentiate when adventure already favorited. https://gohinterlands.atlassian.net/browse/HIN-290
    render_resource(@adventure,
                    flash:{ message: flash_message('success'),
                            type: 'success' })
  else
    track(current_user, 'added adventure to favorite', adventure_uid: @adventure.uid)
  end

  def remove_favorite
    current_user.favorite_adventures.delete(@adventure)
    track(current_user, 'removed adventure from favorite', adventure_uid: @adventure.uid)
    render_resource(@adventure,
                    flash: { message: flash_message('success'),
                             type: 'success' })
  end

  def by_slug
    @adventure = scoped_resources.friendly.find(params[:slug])
    track_show_event @adventure
    render_resource @adventure
  end

  def by_short_uid
    @adventure = scoped_resources.find_by!(short_uid: params[:short_uid])
    track_show_event @adventure
    render_resource @adventure
  end

  def filter
    render_resources paginated_scoped_resources.records
  end
  alias_method :closest, :filter

  private

  def scoped_resources
    case action_name
    when 'featured'
      track(current_user, "views featured adventures")
      super.featured.order(position: :asc, id: :desc)
    when 'favorited'
      track(current_user, "views favorited adventures")
      current_user.favorite_adventures.order(position: :asc, id: :desc)
    when 'filter'
      track(current_user, "performed adventures search", parameters: params[:filter].to_json)
      return AdventureFilter.new(filter_params).search
    when 'closest'
      track(current_user, 'search for closest adventure', params[:coordinate].to_unsafe_h)
      return AdventureFilter.new(closest_params).closest
    else
      track(current_user, "views adventures") if action_name == 'index'
      adventures = super.order(position: :asc, id: :desc)
      if params[:guide_id]
        @index_api_date_version = :nested
        adventures.with_guide_uid(params[:guide_id])
      else
        adventures
      end
    end.listed
  end

  def filter_params
    params
      .fetch(:filter, ActionController::Parameters.new({}))
      .permit(:query, :difficulty, activity_uids: [], activity_titles: [],
              coordinate: [:latitude, :longitude], date_range: [:min, :max],
              price_cents_range: [:min, :max], group_size_range: [:min, :max])
      .merge(is_listed: true)
  end

  def closest_params
    params
      .permit(coordinate: [:latitude, :longitude, :miles])
      .merge(is_listed: true)
  end

  def prepare_adventure
    @adventure = Adventure.listed.find_by_uid!(params[:id])
  end

  def track_show_event adventure
    if adventure.is_featured
      track(current_user, 'views featured adventure', adventure_uid: adventure.uid)
    elsif adventure.is_favorite
      track(current_user, 'views favorited adventure', adventure_uid: adventure.uid)
    else
      track(current_user, 'views adventure', adventure_uid: adventure.uid)
    end
  end
end

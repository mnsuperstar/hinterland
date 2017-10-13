class Api::GuidesController < Api::ResourcesController
  include ::CompanyScoped
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: [:show, :by_slug, :featured]
  before_action :authenticate_user_from_token, only: [:show, :by_slug, :featured]

  def featured
    if current_user
      index
    else
      render json: { resource_klass_name => paginated_scoped_resources.to_api_data('guide_public') }
    end
  end

  def show
    super
    track(current_user, 'views featured guide', guide_uid: @resource.uid) if @resource.is_featured_guide
  end

  def by_slug
    guide = scoped_resources.friendly.find(params[:slug])
    track(current_user, 'views guide by slug', guide_uid: guide.uid)
    render_resource guide
  end

  private

  def resource_klass
    User
  end

  def scoped_resources
    r = super.guides.order(id: :desc)
    if action_name == 'featured'
      track(current_user, "views featured guides")
      r.featured
    elsif action_name.in?(%w(show by_slug))
      r.with_guide_phone_number
    else
      track(current_user, "views guides") if action_name == 'index'
      r
    end
  end

  def api_data_version
    'guide'
  end

  def index_api_data_version
    'guide_index'
  end
end

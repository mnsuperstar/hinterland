class Api::ResourcesController < Api::ModuleController
  def index
    @resources = paginated_scoped_resources
    render_resources @resources
  end

  def show
    render_resource resource
  end

  private

  def resource_klass_name
    @resource_klass_name ||= controller_name
  end

  def resource_klass
    @resource_klass ||= resource_klass_name.classify.constantize
  end

  def scoped_resources
    resource_klass
  end

  def paginated_scoped_resources
    return scoped_resources if params[:page].blank? && params[:per_page].blank?
    scoped_resources
      .page((params[:page].presence || 1).to_i)
      .per((params[:per_page].presence || Kaminari.config.default_per_page).to_i)
      .padding((params[:page_offset].presence || 0).to_i)
  end

  def api_data_version
    @api_date_version || nil
  end

  def index_api_data_version
    @index_api_date_version ||= 'index'
  end

  def render_resources(resources, options = {})
    render json:
      { resource_klass_name => resources.to_api_data(index_api_data_version) }
      .merge(options)
      .merge(pagination_attributes(resources))
  end

  def render_resource(resource, options = {})
    render json:
      { resource_klass_name.singularize => resource.to_api_data(api_data_version) }
      .merge(options)
  end

  def paginate_by_default
    params[:page] ||= 1
  end

  def pagination_attributes(resources)
    if resources.respond_to?(:total_pages)
      {
        current_page: resources.current_page,
        total_pages: resources.total_pages
      }
    else
      {}
    end
  end

  def resource
    @resource ||= scoped_resources.find_by_uid!(params[:id])
  end
end

class Api::PromotionCodesController < Api::ResourcesController
  def show
    resource = scoped_resources.find_valid_by_code(params[:id])
    track(current_user, 'views promotion code', code: params[:id])
    render_resource resource
  end
end

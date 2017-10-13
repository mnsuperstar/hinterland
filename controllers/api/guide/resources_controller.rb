class Api::Guide::ResourcesController < Api::ResourcesController
  before_action :ensure_guide_role

  private

  def ensure_guide_role
    render_error_json t('require_guide', scope: %i(flash api)), status: :forbidden unless current_user.guide?
  end

  def ensure_verified_guide
    render_error_json t('require_verified_guide', scope: %i(flash api)), status: :forbidden unless current_user.is_verified_guide
  end
end

class Api::Adventurer::ResourcesController < Api::ResourcesController
  before_action :ensure_adventurer_role

  private

  def ensure_adventurer_role
    render_error_json t('require_adventurer', scope: %i(flash api)), status: :forbidden unless current_user.adventurer?
  end

  def ensure_verified_adventurer
    if AppSetting['adventurer.skip_verification']
      ensure_adventurer_role
    else
      render_error_json t('require_verified_adventurer', scope: %i(flash api)), status: :forbidden unless current_user.is_verified_adventurer
    end
  end
end

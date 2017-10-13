class Api::AdventurersController < Api::ResourcesController
  def show
    super
    EventTrackingJob.perform_later(current_user, "views other adventurer's profile", user_uid: @resource.uid)
  end

  private

  def resource_klass
    User
  end

  def scoped_resources
    if action_name == 'show'
      super.with_adventurer_phone_number
    else
      super
    end
  end

  def api_data_version
    'adventurer'
  end

  def index_api_data_version
    'adventurer_index'
  end
end

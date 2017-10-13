class Api::Adventurer::AdventuresController < Api::Adventurer::ResourcesController
  def location_subscribe
    if new_location_subscription.save
      track(current_user, 'opts in to non-open state', location_subscription_id: new_location_subscription.id)
      head(:ok)
    else
      render_error_json(new_location_subscription,
                        status: :unprocessable_entity)
    end
  end

  private

  def new_location_subscription
    @location_subscription ||=
      LocationSubscription.new(location_subscription_params)
  end

  def location_subscription_params
    params['location_subscription']
      .permit(:latitude, :longitude)
      .merge(user: current_user)
  end
end

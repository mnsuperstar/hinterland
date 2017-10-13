class UpdateResponseRateJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveJob::DeserializationError) do
    # ignore when object no longer exists
  end

  def perform(obj = User.guides, current_user = nil)
    if obj.is_a?(Booking)
      obj.guide.send(:update_response_rate) if obj.guide
      return
    elsif obj.is_a?(Chat)
      obj = (current_user ? obj.users.where.not(id: current_user.id) : obj.users)
    end

    obj.find_each do |user|
      user.send(:update_response_rate)
    end
  end
end

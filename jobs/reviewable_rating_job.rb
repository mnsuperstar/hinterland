class ReviewableRatingJob < ApplicationJob
  rescue_from(ActiveJob::DeserializationError) do
    # ignore when reviewable no longer exists
  end

  def perform(reviewable)
    reviewable.update_rating if reviewable.respond_to?(:update_rating)
  end
end

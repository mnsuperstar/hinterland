class Api::ReviewsController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!, only: [:index]
  before_action :authenticate_user_from_token, only: [:index]

  def create
    @review = current_user.reviews.new(review_params)
    if @review.save
      track(current_user, "created a review", "#{@review.reviewable_type.underscore}_uid" => @review.reviewable.uid )
      render_resource @review
    else
      render_error_json @review, json: { review: @review.to_api_data }, status: :unprocessable_entity
    end
  end

  private

    def scoped_resources
      if (adventure_uid = params[:adventure_id] || params[:adventure_uid]).present?
        track(current_user, 'views reviews from adventure', adventure_uid: adventure_uid)
        Adventure.find_by_uid!(adventure_uid).reviews
      elsif (guide_uid = params[:guide_id] || params[:guide_uid]).present?
        track(current_user, 'views reviews from guide', guide_uid: guide_uid)
        super.where(reviewable: UsersRole.find_by_user_uid_and_role_name(guide_uid, 'guide'))
      elsif (adventurer_uid = params[:adventurer_id] || params[:adventurer_uid]).present?
        track(current_user, 'views reviews from adventurer', adventurer_uid: adventurer_uid)
        super.where(reviewable: UsersRole.find_by_user_uid_and_role_name(adventurer_uid, 'adventurer'))
      elsif current_user
        track(current_user, 'views their created reviews')
        super.where(reviewer: current_user)
      else
        raise ActiveRecord::RecordNotFound
      end.newest_first
    end

    def review_params
      params.require(:review).permit(:adventure_uid, :booking_uid, :guide_uid, :adventurer_uid, :text, :rating, :title)
    end
end

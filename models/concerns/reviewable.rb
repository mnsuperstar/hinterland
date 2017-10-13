module Reviewable
  extend ActiveSupport::Concern

  included do
    has_many :reviews, as: :reviewable, dependent: :destroy
  end

  def update_rating
    assign_attributes reviews_count: reviews.size, reviews_average_rating: reviews.average(:rating)
    save!(validate: false)
  end

  def reviews_api_attribute
    {
      average_rating: reviews_average_rating,
      count: reviews_count,
      selected_review: reviews.reorder(rating: :desc, created_at: :desc).first.try(:to_api_data, :nested)
    }
  end

  def reviews_api_attribute_rating
    {
      average_rating: reviews_average_rating,
      count: reviews_count
    }
  end
end

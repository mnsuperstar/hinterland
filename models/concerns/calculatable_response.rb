module CalculatableResponse
  extend ActiveSupport::Concern
  included do
    after_commit :schedule_update_response_rate, on: [:create]
  end

  private

  # schedule guide response rate update in 24 hours (+ 5 seconds to handle DB delay)
  def schedule_update_response_rate
    UpdateResponseRateJob.set(wait: 24.hours + 5).perform_later(self, current_user)
  end
end

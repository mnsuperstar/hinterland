class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  http_basic_authenticate_with name: ENV["WEBHOOK_USERNAME"], password: ENV["WEBHOOK_PASSWORD"]

  def create
    case params.delete(:webhook_from)
    when "sendgrid"
      SendgridEvent.create_from_webhook(params.to_unsafe_h)
    else
      if params[:type] == 'account.application.deauthorized'
        StripeEvent.create_from_webhook_params params
      else
        StripeEvent.create_from_stripe_event_id!(params[:id], params[:user_id])
      end
    end
    head(:ok)
  end
end

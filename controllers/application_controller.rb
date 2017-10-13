require 'mixpanel-ruby'
class ApplicationController < ActionController::Base
  include WebAppRoute

  helper_method :web_app_url
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :clear_thread_current
  after_action :clear_thread_current

  def track(subject, event, options = {})
    options[:ip] = request.remote_ip
    EventTrackingJob.perform_later(subject, event, options)
  end

  private

  def clear_thread_current
    %i(current_user current_company current_admin_company).each do |key|
      RequestStore.store[key] = nil
    end
  end
end

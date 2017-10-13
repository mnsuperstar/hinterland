class Api::ModuleController < ApplicationController
  before_action :current_company
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from MultiJson::ParseError, with: :handle_json_error


  private

  def whitelabel_app?
    request.headers['Company-Domain'].present? &&
      request.headers['Company-Domain'] != ENV['APP_DOMAIN']
  end

  def current_company
    if whitelabel_app?
      @current_company = RequestStore.store[:current_company] =
        Company.find_by_domain!(request.headers['Company-Domain'])
    end
  end

  def render_error_json(object, options = {})
    options.reverse_merge!(status: :not_acceptable, json: {})
    options[:json].merge!(error_json(object))
    render options
  end

  def error_json(object)
    if object.is_a? ActiveRecord::Base
      { errors: object.errors, error_messages: object.errors.full_messages }
    else
      { error: object, error_messages: Array(object) }
    end
  end

  def flash_message(key, options = {})
    controller_path = self.class.name.gsub('::', '.').sub(/Controller$/, '').downcase
    t("flash.#{controller_path}.#{action_name}.#{key}", {raise: true}.merge(options))
  rescue I18n::MissingTranslationData
    t("flash.#{controller_path}.#{key}", {raise: true}.merge(options)) rescue t("flash.#{key}", options)
  end


  def authenticate_user_from_token!
    uid, token = params[:auth_token].split('.') if params[:auth_token].present?

    user_scope = User.where(uid: uid)
    user_scope = user_scope.where(company: @current_company) if whitelabel_app?
    user = user_scope.first
    if uid.present? && token.present? &&
       user && Devise.secure_compare(user.auth_token, token) &&
       allow_token_authenticate?(user)
      sign_in user, store: false, run_callbacks: false
      RequestStore.store[:current_user] = user
    else
      render_error_json t('devise.failure.unauthenticated'), status: :unauthorized
      false
    end
  end

  def authenticate_user_from_token
    authenticate_user_from_token! if params[:auth_token].present?
  end

  def handle_record_not_found exception=""
    render_error_json t('flash.api.not_found'), status: :not_found
  end

  def handle_parameter_missing exception
    render_error_json t('flash.api.parameter_missing', param: exception.param) , status: :bad_request
  end

  def handle_json_error exception
    render_error_json t('flash.api.json_parse_error', error_message: exception.message) , status: :bad_request
  end

  def allow_token_authenticate? user
    if user.active_for_authentication?
      true
    else
      render_error_json t(user.inactive_message, scope: [:devise, :failure]), status: :locked
      false
    end
  end

  def authenticate_admin_company_from_token!
    uid, token = params[:company_auth_token].split('.') if params[:company_auth_token].present?

    admin_company_scope = AdminCompany.where(uid: uid)
    admin_company_scope = admin_company_scope.where(company: @current_company) if whitelabel_app?
    admin_company = admin_company_scope.first
    if uid.present? && token.present? &&
       admin_company && Devise.secure_compare(admin_company.auth_token, token) &&
       allow_token_authenticate?(admin_company)
      sign_in admin_company, store: false, run_callbacks: false
      RequestStore.store[:current_admin_company] = admin_company
    else
      render_error_json t('devise.failure.unauthenticated'), status: :unauthorized
      false
    end
  end

  def authenticate_admin_company_from_token
    authenticate_admin_company_from_token! if params[:company_auth_token].present?
  end
end

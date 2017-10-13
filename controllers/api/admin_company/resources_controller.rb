class Api::AdminCompany::ResourcesController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!
  skip_before_action :authenticate_user!
  skip_before_action :current_company

  before_action :authenticate_admin_company_from_token!
  before_action :authenticate_admin_company!

  private
end

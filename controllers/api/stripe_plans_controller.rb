class Api::StripePlansController < Api::ResourcesController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!
end

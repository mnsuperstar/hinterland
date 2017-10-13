module Websocket
  class Authentication
    attr_accessor :uid, :token, :user
    def initialize(args)
      @uid, @token = args[:auth_token].to_s.split('.')
    end

    def user
      @user if @user
      user = User.find_by_uid(uid)
      if uid.present? &&
          token.present? &&
          user &&
          Devise.secure_compare(user.auth_token, token)
        @user = user
      else
        @user = nil
      end
    end
  end
end

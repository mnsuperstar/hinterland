module HasOmniauth
  extend ActiveSupport::Concern

  included do
    attr_accessor :need_omniauth_confirmation
  end

  module ClassMethods

    def find_for_oauth(provider, auth, resource = nil)
      uid, email, token, secret, name =
        if auth.is_a? OmniAuth::AuthHash
          [auth.uid, auth.info.email, auth.credentials.token, auth.credentials.secret, auth.info.name]
        else
          [auth[:uid], auth[:email], auth[:oauth][:token], auth[:oauth][:secret], auth[:name]]
        end

      authentication = Authentication.where(provider: provider, uid: uid).first_or_initialize
      authentication.assign_attributes(token: token, secret: secret)
      authentication.email = email if email.present?
      authentication.name = name if name.present?
      user = resource || authentication.user
      if !resource.nil?

        user.authentications << authentication
        authentication.save
        user.save

      elsif user.nil?
        user = (email.present?) ? User.where(email: email).first_or_initialize : User.new
        if user.new_record?
          user.remote_profile_photo_url = auth[:photo][:profile_photo]
          user.remote_background_photo_url = auth[:photo][:background_photo]
          user.update_attributes(name: name,
                                 is_using_oauth: true,
                                 password: Devise.friendly_token[0, 20]
          )
          user.authentications << authentication if user.valid?
        else
          user.need_omniauth_confirmation = true
        end
      elsif authentication.changed?
        authentication.save
      end
      user
    end
  end

end

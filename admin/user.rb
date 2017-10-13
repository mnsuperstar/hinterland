ActiveAdmin.register User do
  scope :verified_adventurers
  scope :verified_guides
  scope :supports

  permit_params :uid, :auth_token, :email, :password, :first_name, :last_name,
                :bio, :is_using_oauth, :latitude, :longitude, :gender, :birthdate,
                :location, :profile_photo, :background_photo, :past_guides_count,
                :phone_number, :is_verified_guide, :user_type,
                certifications_attributes: [:id, :name, :photo, :_destroy]

  filter :uid
  filter :email
  filter :first_name
  filter :last_name
  filter :gender

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete :password
        params[:user].delete :password_confirmation
      end
      super
    end
    def scoped_collection
      super.includes :roles
    end
  end

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :roles, sortable: 'roles.name' do |resource|
      resource.users_roles.each do |ur|
        status_tag(ur.role_name, ur.is_verified ? :yes : :no)
      end
      nil
    end
    actions
  end

  show do
    panel "Basic attributes" do
      attributes_table_for resource do
        row :id
        row :uid
        row :auth_token
        row :email
        row :email_alias
        row :phone_number
        row :first_name
        row :last_name
        row :bio
        row :gender
        row :birthdate
        row :roles do
          resource.users_roles.each do |ur|
            status_tag(ur.role_name, ur.is_verified ? :yes : :no)
          end
        end
      end
    end

    panel "Additional attributes" do
      attributes_table_for resource do
        row :latitude
        row :longitude
        row :location
        row :past_guides_count
        row :response_rate
        row :is_using_oauth
        row :sign_in_count
        row :failed_attempts
      end
    end

    panel "Timestamps" do
      attributes_table_for resource do
        row :confirmed_at
        row :current_sign_in_at
        row :last_sign_in_at
        row :current_sign_in_ip
        row :last_sign_in_ip
        row :locked_at
        row :created_at
        row :updated_at
      end
    end

    panel "Gallery" do
      attributes_table_for resource do
        row :profile_photo do
          if resource.profile_photo?
            link_to(resource.profile_photo_identifier,
                    resource.profile_photo.url,
                    target: :blank)
          end
        end
        row :background_photo do
          if resource.background_photo?
            link_to(resource.background_photo_identifier,
                    resource.background_photo.url,
                    target: :blank)
          end
        end
      end
    end

    panel 'Credits History' do
      table_for resource.credit_histories do
        column :amount
        column :reason
      end
      render partial: 'admin/amount_credit_form', locals: { resource: resource }
    end
  end

  form(:html => { :multipart => true }) do |f|
    f.semantic_errors
    f.inputs do
      f.input :uid
      f.input :auth_token
      f.input :email
      f.input :password
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :bio
      f.input :is_using_oauth
      f.input :latitude
      f.input :longitude
      f.input :gender
      f.input :birthdate, :as => :date_picker
      f.input :location
      f.input :profile_photo, hint: f.object.profile_photo? ?
                                      link_to(f.object.profile_photo_identifier,
                                              f.object.profile_photo.url,
                                              target: :blank) :
                                      nil
      f.input :background_photo, hint: f.object.background_photo? ?
                                         link_to(f.object.background_photo_identifier,
                                                 f.object.background_photo.url,
                                                 target: :blank) :
                                         nil
      f.input :user_type, label: 'Role', as: :select, collection: Role::AVAILABLE_ROLES.map { |role| [role, role] }
    end
    f.inputs "Guide attributes" do
      f.has_many :certifications, allow_destroy: true do |certificate|
        certificate.input :name
        certificate.input :photo, :hint => certificate.object.photo? ?
                                             link_to(certificate.object.photo_identifier,
                                                     certificate.object.photo.url) :
                                             nil
      end
      f.input :past_guides_count, as: :select, collection: User.past_guides_counts.keys
      f.input :is_verified_guide, as: :boolean
    end if f.object.guide?
    f.actions
  end

  action_item :toggle_support_role, only: %i(show edit) do
    link_to user.has_role?('support') ? 'Remove support role' : 'Add support role',
            toggle_support_role_admin_user_path(user),
            method: :put,
            data: { confirm: "Toggle #{user.email} support role?" }
  end

  member_action :toggle_support_role, method: :put do
    support_role = Role.where(name: 'support').first_or_create!
    is_support = resource.has_role?('support')
    if is_support
      resource.roles.delete support_role
    else
      resource.roles << support_role
    end
    redirect_back fallback_location: admin_user_path(resource), notice: "User support role #{is_support ? 'removed' : 'added'}."
  end

  action_item :confirm, only: %i(show edit) do
    link_to 'Confirm email',
            confirm_admin_user_path(user),
            method: :put,
            data: { confirm: "Confirm #{user.email}?" } unless user.confirmed?
  end

  member_action :confirm, method: :put do
    # confirm! is deprecated
    # http://www.rubydoc.info/github/plataformatec/devise/master/Devise/Models/Confirmable#confirm!
    resource.confirm
    redirect_back fallback_location: admin_user_path(resource), notice: "User confirmed."
  end

  member_action :update_credit, method: :put do
    resource.add_credit_amount!(Money.new(BigDecimal.new(params[:user][:credit_amount]) * 100), reason: "by admin: #{current_admin_user.email}")
    redirect_back fallback_location: admin_user_path(resource), notice: "Credit amount updated."
  end
end

ActiveAdmin.register AdminUser do
  menu parent: 'users'

  permit_params :email, :password, :password_confirmation

  filter :email

  controller do
    def update
      if params[:admin_user][:password].blank?
        params[:admin_user].delete :password
        params[:admin_user].delete :password_confirmation
      end
      super
    end
  end

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    column :created_at
    actions
  end

  form do |f|
    f.inputs "Admin Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end

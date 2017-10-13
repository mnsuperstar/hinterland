ActiveAdmin.register AdminCompany, namespace: :company_portal do
  menu false

  permit_params :email, :password, :password_confirmation

  filter :email

  controller do
    def scoped_collection
      super.where(id: current_admin_company)
    end

    def update
      if params[:admin_company][:password].blank?
        params[:admin_company].delete :password
        params[:admin_company].delete :password_confirmation
      end
      super
    end
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

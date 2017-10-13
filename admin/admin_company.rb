ActiveAdmin.register AdminCompany do
  menu parent: 'users'

  permit_params :email, :password, :password_confirmation, :company_id

  filter :email

  controller do
    def update
      if params[:admin_company][:password].blank?
        params[:admin_company].delete :password
        params[:admin_company].delete :password_confirmation
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
    actions defaults: false do |admin_company|
      link_to "Login as #{admin_company.email}", login_as_admin_admin_company_path(admin_company), target: '_blank'
    end
  end

  form do |f|
    f.inputs "Admin Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :company_id, as: :select, collection: Company.all.map { |u| [u.name, u.id] },
              input_html: { class: 'select2' }
    end
    f.actions
  end

  member_action :login_as, method: :get do
    admin = AdminCompany.find(params[:id])
    sign_in(admin, bypass: true)
    redirect_to company_portal_root_path
  end
end

ActiveAdmin.register Company, namespace: :company_portal do
  menu false
  actions :all, except: %i(new create destroy)
  permit_params :uid, :name, :email, :phone_number, :address, :custom_domain_candidate

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end

    def scoped_collection
      super.where(id: current_admin_company.company)
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :email
      f.input :phone_number
      f.input :address
      f.input :custom_domain_candidate
    end
    f.actions
  end
end

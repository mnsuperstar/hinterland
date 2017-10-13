ActiveAdmin.register_page "Dashboard", namespace: :company_portal do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  action_item :current_admin_company do
    link_to "Company", company_portal_company_path(current_admin_company.company)
  end
end

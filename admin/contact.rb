ActiveAdmin.register Contact do
  actions :all, except: %i(new create edit update destroy)
  remove_filter :message

  index do
    id_column
    column :full_name
    column :email
    column :phone
    column :company
    actions
  end
end

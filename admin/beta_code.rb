ActiveAdmin.register BetaCode do
  menu parent: 'Users'

  permit_params :code, :name, :description, :limit, :valid_from, :valid_until

  form do |f|
    f.inputs do
      f.semantic_errors
      f.input :code
      f.input :name
      f.input :description
      f.input :limit
      f.input :valid_from, as: :datepicker
      f.input :valid_until, as: :datepicker
      f.actions
    end
  end

  index do
    column :code
    column :name
    column :description
    column :limit
    column :valid_from
    column :valid_until
    actions
  end

  show do
    attributes_table do
      row :code
      row :name
      row :description
      row :limit
      row :valid_from
      row :valid_until
    end
  end
end

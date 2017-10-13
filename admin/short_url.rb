ActiveAdmin.register ShortUrl do
  menu parent: 'dashboard'
  permit_params :long_url, :short_uid

  index do
    selectable_column
    id_column
    column :long_url
    column :short_uid
    column :short_url
    column :access_count
    actions
  end

  show do
    attributes_table_for resource do
      row :id
      row :short_uid
      row :long_url
      row :short_url
      row :access_count
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :long_url
      f.input :short_uid
    end
    f.actions
  end
end

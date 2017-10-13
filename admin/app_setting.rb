ActiveAdmin.register AppSetting do
  menu parent: 'dashboard'
  actions :all, except: %i(show new create destroy)

  permit_params :value

  index do
    selectable_column
    id_column
    column :name
    column :value do |resource|
      resource.value_for_input
    end
    column :value_type
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :value,
        input_html: { value: f.object.value_for_input,
                      placeholder: app_setting_value_hint(f.object, false) },
        hint: app_setting_value_hint(f.object)
    end
    f.actions
  end
end

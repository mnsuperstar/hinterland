ActiveAdmin.register PromotionCode do
  menu parent: 'Bookings'

  permit_params :code, :name, :description, :limit, :amount_percentage, :valid_from, :valid_until, :amount

  filter :code
  filter :name
  filter :amount
  filter :amount_percentage
  filter :limit
  
  form do |f|
    f.inputs do
      f.semantic_errors
      f.input :code
      f.input :name
      f.input :description
      f.input :limit
      f.input :amount
      f.input :amount_percentage
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
    column :promotion_value
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
      row :promotion_value
      row :valid_from
      row :valid_until
    end
  end
end

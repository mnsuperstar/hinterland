ActiveAdmin.register OpenLocation do
  permit_params :state, :state_code, :city, :image, :location_id

  filter :state
  filter :state_code
  filter :city

  form(:html => { :multipart => true }) do |f|
    f.semantic_errors
    f.inputs do
      f.input :location, input_html: { class: 'select2' }
      f.input :state
      f.input :state_code
      f.input :city
      f.input :image, :hint => open_location.image? ? link_to(f.object.image_identifier, f.object.image.url, target: :blank) : nil
    end
    f.actions
  end

  index do
    selectable_column
    id_column
    column :state_code
    column :city
    column :image
    actions
  end
end

ActiveAdmin.register Location do
  menu parent: 'adventures'

  permit_params :latitude, :longitude, :zipcode, :country_code, :city, :state, :street_address, :provice, :district, :full_address

  filter :zipcode
  filter :city
  filter :state
  filter :street_address

   index do
    id_column
    column :zipcode
    column :state
    column :city
    column :street_address
    actions
  end

  member_action :get_location, method: :get do
    render json: Location.select(:city, :state).find(params[:id])
  end
end

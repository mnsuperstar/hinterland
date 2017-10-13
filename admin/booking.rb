ActiveAdmin.register Booking do
  actions :all, except: %i(new create destroy)
  permit_params :start_on, :end_on, :number_of_adventurers

  filter :uid
  filter :status
  filter :booking_number
  filter :number_of_adventurers
  filter :total_price_currency
  filter :start_on
  filter :promotion_code

  action_item :cancel, only: [:show] do
    cancel_link booking
  end

  index do
    id_column
    column :uid
    column :booking_number
    column :promotion_code
    column :start_on
    column :end_on
    column :number_of_adventurers
    column :status
    actions
    actions defaults: false do |booking|
      cancel_link booking
    end
  end

  member_action :cancel, method: :put do
    resource.canceled!
    redirect_back fallback_location: admin_bookings_path, notice: "Booking has been canceled"
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :start_on, as: :datepicker
      f.input :end_on, as: :datepicker
      f.input :number_of_adventurers
    end
    f.actions
  end
end

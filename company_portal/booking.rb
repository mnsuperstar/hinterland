ActiveAdmin.register Booking, namespace: :company_portal do
  actions :all, except: %i(new create destroy)
  permit_params :guide_id, :skip_validation_for_availability

  controller do
    def scoped_collection
      super.where(company: current_admin_company.company)
    end
  end

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
      f.input :guide_id, as: :select,
              collection: AdventuresGuidesAssignment.where(adventure: Booking.find(params[:id]).adventure).map { |u| [u.guide.name, u.guide.id] },
              input_html: { class: 'select2' }
      f.input :skip_validation_for_availability, :input_html => { :value => false }, as: :hidden
    end
    f.actions
  end
end

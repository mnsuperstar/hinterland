ActiveAdmin.register Review, as: 'BookingReview' do
  menu false
  actions :all, except: %i(edit update destroy)
  permit_params :text, :rating, :title, :reviewer_id, :booking_uid

  controller do
    def create
      booking = Booking.find_by_uid!(params[:review][:booking_uid])
      params[:review][:reviewer_id] = booking.adventurer.id
      super
    end
  end

  form do |f|
    f.inputs do
      f.semantic_errors
      f.input :booking_uid, as: :select, collection: Booking.reviewable.collect {|booking| [booking.booking_number || booking.id, booking.uid] }
      f.input :rating
      f.input :title
      f.input :text
      f.actions
    end
  end

  show do
    attributes_table do
      row :reviewer
      row :reviewable do
        reviewable_link resource.reviewable
      end
      row :rating
      row :title
      row :text
    end
  end
end

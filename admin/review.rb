ActiveAdmin.register Review do
  actions :all, except: %i(new create)
  permit_params :text, :rating, :title, :reviewer_id

  filter :uid
  filter :reviewer
  filter :reviewable_type
  filter :title
  filter :text
  filter :rating
  filter :created_at

  action_item :new_guide_reviews do
    link_to "New Guide Reviews", new_admin_guide_review_path
  end

  action_item :new_adventurer_reviews do
    link_to "New Adventurer Reviews", new_admin_adventurer_review_path
  end

  action_item :new_booking_reviews do
    link_to "New Booking Reviews", new_admin_booking_review_path
  end

  index do
    column :reviewer
    column :reviewable do |resource|
      reviewable_link resource.reviewable
    end
    column :title
    column :rating
    actions
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

  form do |f|
    f.inputs do
      f.semantic_errors
      f.input :reviewer
      f.input :rating
      f.input :title
      f.input :text
      f.actions
    end
  end
end

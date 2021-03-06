ActiveAdmin.register Review, as: 'AdventurerReview' do
  menu false
  actions :all, except: %i(edit update destroy)
  permit_params :text, :rating, :title, :reviewer_id, :adventurer_uid

  form do |f|
    f.inputs do
      f.semantic_errors
      f.input :reviewer
      f.input :adventurer_uid, as: :select, collection: UsersRole.find_adventurer.collect {|ur| [ur.user.first_name, ur.user.uid]}
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

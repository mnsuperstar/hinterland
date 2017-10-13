ActiveAdmin.register Activity do

permit_params :title, :uid, :thumbnail, :parent_id, :is_hidden, :background

  filter :title
  filter :is_hidden

  form(:html => { :multipart => true }) do |f|
    f.semantic_errors
    f.inputs do
      f.input :parent
      f.input :title
      f.input :thumbnail, :hint => activity.thumbnail? ?
                                     link_to(f.object.thumbnail_identifier,
                                             f.object.thumbnail.url,
                                             target: :blank) :
                                     nil
      f.input :background, :hint => activity.background? ?
                                      link_to(f.object.background_identifier,
                                              f.object.background.url,
                                              target: :blank) :
                                      nil
      f.input :is_hidden
    end
    f.actions
  end

  show do
    attributes_table do
      row :parent
      row :title
      row :is_hidden
      row :thumbnail do
        if activity.thumbnail?
          link_to(activity.thumbnail_identifier,
                  activity.thumbnail.url,
                  target: :blank)
        end
      end
      row :background do
        if activity.background?
          link_to(activity.background_identifier,
                  activity.background.url,
                  target: :blank)
        end
      end
    end

    panel 'Children' do
      table_for activity.children do
        column :uid do |c_a|
          link_to c_a.uid, [:admin, c_a]
        end
        column :title
        column :thumbnail do |activity|
           activity.thumbnail? ? status_tag("exists", :yes) : status_tag("non-existed", :no)
        end
        column :background do |activity|
           activity.background? ? status_tag("exists", :yes) : status_tag("non-existed", :no)
        end
      end
    end
  end

  index do
    id_column
    column :uid
    column :parent
    column :title
    column :is_hidden
    column :thumbnail do |activity|
       activity.thumbnail? ? status_tag("exists", :yes) : status_tag("non-existed", :no)
    end
    column :background do |activity|
       activity.background? ? status_tag("exists", :yes) : status_tag("non-existed", :no)
    end
    actions
  end
end

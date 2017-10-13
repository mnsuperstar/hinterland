ActiveAdmin.register Adventure, namespace: :company_portal do
  include ActiveAdmin::SortableTable # creates the controller action which handles the sorting
  config.sort_order = 'position_asc'

  controller do
    def scoped_collection
      super.where(company: current_admin_company.company)
    end

    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  permit_params :user_id, :uid, :short_uid, :title, :description, :inclusions,
                :rundowns, :is_featured, :price_cents, :price_currency,
                :location_id, :location_name, :location_note, :group_size,
                :number_of_people_included, :additional_price, :preparations,
                :duration, :skip_ensure_editable, :is_listed, :difficulty,
                activity_ids: [], guide_ids: [],
                adventure_images_attributes: [:id, :order_number, :file, :_destroy],
                adventure_dates_attributes: [:id, :start_on, :end_on, :_destroy]

  filter :title
  filter :location_name
  filter :is_listed
  filter :uid
  filter :price_cents
  filter :is_featured
  filter :group_size

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :is_featured
      f.input :is_listed
      f.input :uid, hint: 'Unique ID used for communication with client App.'
      f.input :short_uid, hint: 'Short unique ID used in share URL.'
      f.input :title
      f.input :group_size, hint: 'Maximum number of participants for a single booking.'
      f.input :duration, as: :radio, collection: Adventure.durations.keys
      f.input :difficulty, as: :radio, collection: Adventure.difficulties.keys
      f.input :description
      f.input :inclusions, hint: 'comma separated', input_html: { value: f.object.inclusions.try(:join, ',') }
      f.input :rundowns, hint: 'comma separated', input_html: { value: f.object.rundowns.try(:join, ',') }
      f.input :preparations, hint: 'comma separated', input_html: { value: f.object.preparations.try(:join, ',') }
      f.input :price_cents, hint: 'Base adventure price for a single day.'
      f.input :number_of_people_included, hint: 'Maximum number of participants included in base price.'
      f.input :additional_price, hint: 'Additional price per person outside number of people included.'
      f.input :location, input_html: { class: 'select2' }
      f.input :location_name, hint: 'Adventure location name. Override location field.'
      f.input :location_note
      f.input :skip_ensure_editable, :input_html => { :value => true }, as: :hidden
      f.input :activities, required: true, as: :select,
              collection: Activity.roots.includes(children: :children).options_for_multi_select,
              input_html: {multiple: true, class: 'select2'}
      f.input :guides, required: true, as: :select,
              collection: current_admin_company.company.guides.map { |u| [u.name, u.id] },
              input_html: {multiple: true, class: 'select2'}
      f.has_many :adventure_dates, allow_destroy: true do |date|
          date.input :start_on, as: :datepicker
          date.input :end_on, as: :datepicker
      end
      f.has_many :adventure_images, allow_destroy: true, sortable: :order_number do |image|
        image.input :file,
                    :hint => image.object.file? ?
                               image.template.link_to(image.object.file.url, image.object.file.url, target: :blank) : nil
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :is_featured
      row :is_listed
      row :id
      row :uid
      row :share_url
      row :title
      row :group_size
      row :duration
      row :difficulty
      row :description
      row :inclusions do |adventure|
        content_tag :ul do
          safe_join(adventure.inclusions.map {|s| content_tag :li, s })
        end if adventure.inclusions
      end
      row :rundowns do |adventure|
        content_tag :ul do
          safe_join(adventure.rundowns.map {|s| content_tag :li, s })
        end if adventure.rundowns
      end
      row :preparations do |adventure|
        content_tag :ul do
          safe_join(adventure.preparations.map {|s| content_tag :li, s })
        end if adventure.preparations
      end
      row :price
      row :number_of_people_included
      row :additional_price
      row :location
      row :location_name
      row :location_note
      row :activities do |adventure|
        adventure.activities.pluck(:title).to_sentence
      end
      row :reviews_count
      row :reviews_average_rating
      row :created_at
      row :updated_at
    end

    panel 'Guides' do
      table_for adventure.adventures_guides_assignments do
        column :guide
      end
    end

    panel 'Images' do
      table_for adventure.adventure_images, id: 'adventure_image' do
        column :order_number do |image|
          image.order_number.present? ? image.order_number + 1 : '-'
        end

        column :image do |image|
          link_to image.file_identifier, image.file.url, target: :blank
        end
      end
    end

    panel 'Reviews' do
      table_for adventure.reviews do
        column :id do |r|
          link_to r.id, [:admin, r]
        end
        column :reviewer do |r|
          link_to r.reviewer.display_name, [:admin, r.reviewer]
        end
        column :rating
        column :text
      end
    end

    panel 'Bookings' do
      table_for adventure.bookings do
        column :id do |r|
          link_to r.id, [:admin, r]
        end
        column :booking_number
        column :adventurer
        column :start_on
        column :end_on
        column :status
      end
    end
  end

  index do
    handle_column sort_url: -> (adventure) { sort_admin_adventure_path(adventure) }
    selectable_column
    id_column
    column :title
    column :reviews_average_rating
    column :price
    column :is_featured
    column :created_at
    actions
  end

  batch_action :featured do |ids|
    Adventure.find(ids).each do |adventure|
      adventure.update_attributes is_featured: true
    end
    redirect_to collection_path, alert: "Adventures have been featured."
  end

  batch_action :unlist do |ids|
    Adventure.find(ids).each do |adventure|
      adventure.update_attributes is_listed: false
    end
    redirect_to collection_path, alert: "Adventures have been unlisted."
  end

  action_item :list_toggle, only: %i(edit show) do
    link_to(adventure.is_listed ? 'Unlist' : 'List',
            list_toggle_admin_adventure_path(adventure),
            method: :put,
            data: { confirm: "Set #{adventure.title} as #{resource.is_listed ? 'unlisted' : 'listed'}?" })
  end

  member_action :list_toggle, method: :put do
    if resource.send(resource.is_listed ? :unlist : :list)
      redirect_back(fallback_location: admin_adventure_path(resource),
                    notice: "Adventure has been #{resource.is_listed ? 'listed' : 'unlisted'}.")
    else
      redirect_back(fallback_location: admin_adventure_path(resource),
                    alert: resource.errors.full_messages.join(', '))
    end
  end
end

ActiveAdmin.register User, as: 'Guide' do
  menu parent: 'users'
  scope :guides, default: true
  scope :featured_guides
  scope :unverified_guides
  scope 'Valid ACH', :has_valid_ach
  scope 'Invalid ACH', :has_invalid_ach

  filter :uid
  filter :email
  filter :first_name
  filter :last_name
  filter :gender

  actions :all, except: %i(new create edit update destroy)
  batch_action :update_slugs do |ids|
    User.find(ids).each(&:save!)
    redirect_back fallback_location: admin_guides_path,
      notice: "Slugs are successfully updated"
  end
  controller do
    def scoped_collection
      super.includes(:users_roles)
    end
  end

  index do
    selectable_column
    id_column
    column :uid do |user|
      link_to user.uid, admin_guide_path(user)
    end
    column :email
    column :first_name
    column :last_name
    column :featured, sortable: 'users_roles.is_featured' do |user|
      user.is_featured_guide ? status_tag("Yes", :yes) : status_tag("No", :no)
    end
    column :verified, sortable: 'users_roles.is_verified' do |user|
      user.is_verified_guide ? status_tag("Yes", :yes) : status_tag("No", :no)
    end
    column :has_ach do |user|
      user.has_ach ? status_tag('Yes', :yes) : status_tag('No', :no)
    end
    actions
    actions defaults: false do |user|
      link_to "#{user.is_featured_guide ? 'Remove from' : 'Add to'} featured", toggle_featured_admin_guide_path(user), method: :put
    end
    actions defaults: false do |user|
      link_to "#{user.is_verified_guide ? 'Remove from' : 'Add to'} verified", toggle_verified_admin_guide_path(user), method: :put
    end
  end

  action_item :update_slug, only: %i(show edit) do
    link_to 'Update Slug',
      update_slug_admin_guide_path(guide),
      method: :put,
      data: { confirm: "update #{guide.email} slug?" }
  end

  member_action :update_slug, method: :put do
    resource.save!
    redirect_back fallback_location: admin_guide_path(resource),
      notice: "#{resource.email}'s slug is successfully updated"
  end

  member_action :toggle_featured, method: :put do
    is_featured = !resource.is_featured_guide
    resource.users_role_for('guide').update_attributes is_featured: is_featured
    redirect_back fallback_location: admin_guides_path, notice: "Guide #{is_featured ? 'added to' : 'removed from'} featured list."
  end

  member_action :toggle_verified, method: :put do
    is_verified_guide = !resource.is_verified_guide
    resource.users_role_for('guide').update_attributes is_verified: is_verified_guide
    UserMailer.notify_partner_application_email_verified(resource).deliver_later if resource.email_notification
    redirect_back fallback_location: admin_guides_path, notice: "Guide #{is_verified_guide ? 'added to' : 'removed from'} verified list."
  end

  show do
    attributes_table do
      row :uid
      row :email
      row :first_name
      row :last_name
      row 'featured' do
        resource.is_featured_guide ? status_tag('Yes', :yes) : status_tag('No', :no)
      end
      row 'verified' do
        resource.is_verified_guide ? status_tag('Yes', :yes) : status_tag('No', :no)
      end
      row 'activity' do
        resource.activities.map(&:title).join(', ')
      end
      row 'experienced' do
        resource.has_guide_experience ? status_tag('Yes', :yes) : status_tag('No', :no)
      end
      row 'certificated' do
        resource.has_guide_certifications ? status_tag('Yes', :yes) : status_tag('No', :no)
      end
      row :bio
      row 'photo' do
        resource.profile_photo? ? link_to(resource.profile_photo.url, resource.profile_photo.url) : '-'
      end
      row :phone_number
      row :email_alias
      row "Pending Money" do
        resource.received_bookings.pending.guide_sum.format
      end
      row "Accepted Money" do
        resource.received_bookings.accepted.guide_sum.format
      end
      row :past_guides_count
      row :slug
      row :has_ach do
        resource.has_ach ? status_tag('Yes', :yes) : status_tag('No', :no)
      end
    end

    panel 'Adventures' do
      table_for resource.adventures do
        column :title do |adventure|
          link_to adventure.title, admin_adventure_path(adventure)
        end
        column :description
        column :location
      end
    end

    panel 'Certifications' do
      table_for resource.certifications do
        column :name
        column :photo do |c|
          link_to c.photo.url, c.photo.url if c.photo?
        end
      end
    end
  end
end

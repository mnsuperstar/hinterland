# == Schema Information
#
# Table name: devices
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  uid             :string
#  parse_object_id :string
#  token           :string
#  os              :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#


ActiveAdmin.register Device do
  menu parent: 'users'

  permit_params :user_id, :uid, :endpoint_arn, :token, :os, :is_disabled

  filter :user_id
  filter :os
  filter :created_at

  member_action :send_push_notification, method: :post do
    begin
      if params[:message].present?
        options = params[:options].present? ? ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(params[:options])) : {}
        resource.send_message params[:message], options
        redirect_to admin_device_path(resource), notice: "Push notification sent."
      else
        redirect_to admin_device_path(resource), alert: "Message required."
      end
    rescue JSON::ParserError
      redirect_to admin_device_path(resource), alert: "Invalid options JSON."
    end
  end

  index do
    id_column
    column :user
    column :uid
    column :is_disabled
    actions
  end

  show do
    attributes_table do
      row :id
      row :uid
      row :user
      row :token
      row :endpoint_arn
      row :os
      row :is_disabled
      row :created_at
      row :updated_at
    end

    panel 'Send push notification' do
      render partial: 'push_notification_form', locals: { resource: resource }
    end
  end

end

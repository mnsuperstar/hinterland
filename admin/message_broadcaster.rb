ActiveAdmin.register_page "Message Broadcaster" do
  menu parent: 'dashboard'

  content title: 'Broadcast Message' do
    render partial: 'broadcaster_form'
  end

  page_action :broadcast_message, method: :post do
    begin
      if params[:message].present?
        options = params[:options].present? ? ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(params[:options])) : {}
        PushNotification::Broadcaster.new.send_message(params[:message], options)
        redirect_to admin_message_broadcaster_path, notice: "Push notification sent."
      else
        redirect_to admin_message_broadcaster_path, alert: "Message required."
      end
    rescue JSON::ParserError
      redirect_to admin_message_broadcaster_path, alert: "Invalid options JSON."
    end
  end
end

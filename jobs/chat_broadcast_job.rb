class ChatBroadcastJob < ApplicationJob
  queue_as :default

  def perform(action, obj)
    if action == 'send_message'
      obj.recipients_except_sender.each do |user|
        ChatChannel.broadcast_to user, {
          action: action,
          status: 'ok',
          data: { message: obj.to_api_data }
        }
      end
    end
  end
end

# Be sure to restart your server when you modify this file. Action Cable runs in an EventMachine loop that does not support auto reloading.
# require "#{Rails.root}/app/services/websocket/authentication"
class ChatChannel < ApplicationCable::Channel
  def init_chat(data)
    return unless authenticated?
    chat = Chat.find_for_user_uids([data['chat']['peer_uid'], current_user.uid])
    if chat
      current_user.user_chats.find_by(chat: chat).try(:read!)
    else
      chat = Chat.new(chat_params)
      unless chat.save
        broadcast_to current_user, 'error', chat.errors.full_messages
        return
      end
    end
    broadcast_to current_user, 'ok', chat, 'ws'
  end

  def send_message(data)
    return unless authenticated?
    chat = current_user.chats.find_by_uid(data['message'].delete('chat_uid'))
    if !chat
      broadcast_to current_user, 'error', I18n.t('flash.api.not_found')
      return
    end
    message = chat.messages.new(message_params)
    if message.save
      EventTrackingJob.perform_later(current_user, "sends message",
                                     chat_uid: chat.uid,
                                     message_uid: message.uid,
                                     ip: connection.send(:request).try(:remote_ip)
                                    )
      current_user.user_chats.find_by(chat: chat).try(:read!)
    else
      broadcast_to current_user, 'error', message.errors.full_messages
    end
  end

  def read_chat(data)
    return unless authenticated?
    chat = current_user.chats.find_by_uid(data['chat'].delete('uid'))
    if !chat
      broadcast_to current_user, 'error', I18n.t('flash.api.not_found')
      return
    end
    current_user.user_chats.find_by(chat: chat).read!
    broadcast_to current_user, 'ok', chat, 'ws'
  end

  private

  def chat_params
    chat_params = @data.require(:chat).permit(:peer_uid)
    @peer = User.find_by_uid(chat_params.delete(:peer_uid))
    chat_params.merge(users: [current_user, @peer].compact)
  rescue ActionController::ParameterMissing => e
    broadcast_to current_user, 'parameter_missing', I18n.t('flash.api.parameter_missing', param: e.param)
    raise
  end

  def message_params
    @data.require(:message).permit(:content).merge(user: current_user)
  rescue ActionController::ParameterMissing => e
    broadcast_to current_user, 'parameter_missing', I18n.t('flash.api.parameter_missing', param: e.param)
    raise
  end

  def broadcast_to user, status = 'ok', obj = nil, namespace = nil
    self.class.broadcast_to user, {
      action: @data['action'],
      status: status,
      data: status != 'ok' ? { error_messages: Array(obj) } :
              obj.is_a?(ActiveRecord::Base) ? { obj.class.name.downcase => obj.to_api_data(namespace) } :
              obj
    }
  end
end

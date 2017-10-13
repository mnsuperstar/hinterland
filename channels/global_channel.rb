# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class GlobalChannel < ApplicationCable::Channel
  def subscribed
    connection.connect if connection_uuid.blank?
    stream_from(global_broadcasting) unless find_stream_from(global_broadcasting)
  end

  def unsubscribed
    connection.current_user = nil
    stop_all_streams
  end

  def authenticate(data)
    authentication = Websocket::Authentication.new(auth_token: data['auth_token'])
    connection.current_user = authentication.user
    if current_user
      ActionCable.server.broadcast global_broadcasting, {
        action: 'authenticate',
        status: 'ok',
        data: {
          user: current_user.to_api_data(:chat)
        }
      }
      stream_for current_user
    else
      ActionCable.server.broadcast global_broadcasting, {
        action: 'authenticate',
        status: 'error',
        data: {
          error_messages: ['Invalid auth_token.']
        }
      }
    end
  end

  def unauthenticate(data)
    ActionCable.server.broadcast global_broadcasting, {
      action: 'unauthenticate',
      status: 'ok'
    }
    stop_all_streams
    connection.current_user = nil
    stream_from(global_broadcasting)
  end
end

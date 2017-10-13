module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def subscribed
      return unless authenticated? "subscribe"
      stream_from current_user_broadcasting
    end

    def unsubscribed
      stop_stream current_user_broadcasting
    end

    private

    def dispatch_action(action, data)
      @data = ActionController::Parameters.new(data)
      super
    end

    def authenticated? command = "message"
      return true if current_user
      ActionCable.server.broadcast global_broadcasting, {
        action: @data.try(:[], "action") || command,
        status: 'unauthenticated'
      }
      false
    end

    def stop_stream broadcastings
      streams.delete_if do |broadcasting, callback|
        if broadcasting.in? Array(broadcastings)
          pubsub.unsubscribe broadcasting, callback
          logger.info "#{self.class.name} stopped streaming from #{broadcasting}"
          true
        else
          false
        end
      end
    end

    def find_stream_from broadcastings
      streams.detect do |broadcasting, callback|
        broadcasting.in? Array(broadcastings)
      end
    end

    def global_broadcasting
      "connection:#{connection_uuid}"
    end

    def current_user_broadcasting
      current_user ? broadcasting_for([channel_name, current_user]) : nil
    end
  end
end

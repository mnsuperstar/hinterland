module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :connection_uuid, :current_user

    def connect
      loop do # make sure uuid unique, TODO: this won't ensure uniqueness across actioncable servers
        uuid = SecureRandom.uuid
        self.connection_uuid = uuid unless ActionCable.server.connections.detect{|c| c.connection_uuid == uuid}
        break if connection_uuid
      end
    end
  end
end

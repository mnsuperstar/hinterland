class MissedChatMessagesJob < ApplicationJob
  queue_as :default

  def perform
    missed_chats = UserChat.missed.includes(:user, :chat)
    missed_chats.find_each do |uc|
      uc.notify!
    end
  end
end

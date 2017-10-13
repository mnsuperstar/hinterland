class Api::ChatsController < Api::ResourcesController
  include ::CompanyScoped

  def unread_count
    render json: { unread_count: current_user.chats.with_unread_messages.count }
  end

  private

  def scoped_resources
    resources = current_user.chats.with_has_unread_messages.order(updated_at: :desc)
    action_name == 'index' ? resources.with_messages : resources
  end
end

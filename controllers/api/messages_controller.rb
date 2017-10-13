class Api::MessagesController < Api::ResourcesController
  include ::CompanyScoped
  before_action :prepare_chat
  before_action :paginate_by_default, only: [:index]
  after_action :update_user_chat_read_at, only: [:index, :create]

  def create
    @message = @chat.messages.new(message_params)
    if @message.save
      track(current_user, "sends message", chat_uid: @chat.uid, message_uid: @message.uid)
      render_resource @message
    else
      render_error_json @message, json: { message: @message.to_api_data }, status: :unprocessable_entity
    end
  end

  def destroy
    @message = scoped_resources.find_by!(uid: params[:id])
    if @message.destroy
      head :ok
    else
      render_error_json @message, status: :not_acceptable
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :image_content).merge(user: current_user)
  end

  def prepare_chat
    @chat = current_user.chats.find_by_uid!(params[:chat_id] || params['message'].try(:delete, 'chat_uid'))
  end

  def scoped_resources
    @messages = @chat.messages.ordered
    if params[:before]
      @messages = @messages.before(params[:before])
    elsif params[:after]
      @messages = @messages.after(params[:after]) if params[:after]
    end
    @messages
  end

  def update_user_chat_read_at
    current_user.user_chats.find_by(chat: @chat).try(:read!)
  end
end

class ChatsController < ApplicationController
  def new
    @chat = Chat.new
    @interview = secure_interview_for_user
  end

  def create
    @chat = Chat.new(chat_params)
    @interview = secure_interview_for_user
    @chat.interview = @interview

    if @chat.save
      Message.create(role: "assistant",
                     content: "Bonjour ! Pour commencer, parlez-moi de votre parcours et expliquez moi pourquoi vous avez choisi de répondre à notre annonce", chat: @chat) # rubocop:disable Layout/LineLength
      redirect_to chat_path(@chat)
    else
      @interview = @chat.interview
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:id])
    @chat_role = ChatRole.find(@chat.chat_role_id)
    @interview = @chat.interview
    @message = Message.new
  end

  private

  def secure_interview_for_user
    @interviews = Interview.all.where(user: current_user)
    @interviews.find(params[:interview_id])
  end

  def chat_params
    params.require(:chat).permit(:title, :chat_role_id)
  end
end

class ChatsController < ApplicationController
  def create
    @interview = Interview.find(params[:interview_id])

    @chat = Chat.new(title: "Untitled")
    @chat.interview = @interview
    @chat.user = current_user

    if @chat.save
      redirect_to chat_path(@chat)
    else
      @chats = @interview.chats.where(user: current_user)
      render "interviews/show"
    end
  end

  def show
    @chat    = current_user.chats.find(params[:id])
    @message = Message.new
  end
end

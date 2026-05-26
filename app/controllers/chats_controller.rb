class ChatsController < ApplicationController
  def new
    @chat = Chat.new
    @interviews = Interview.all.where(user: current_user)
    @interview = @interviews.find(params[:interview_id])
  end

  def create
    @interviews = Interview.all.where(user: current_user)
    @interview = @interviews.find(params[:interview_id])

    @chat = Chat.new(title: "Untitled")
    @chat.interview = @interview

    # temporary, must be the role selected by the user
    @chat.chat_role = ChatRole.find_by(id: 4)

    if @chat.save
      redirect_to chat_path(@chat)
    else
      @chats = @interview.chats
      render "interviews/show"
    end
  end

  def show
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:id])
    @interview = @chat.interview
    @message = Message.new
  end
end

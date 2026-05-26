class MessagesController < ApplicationController
  # SYSTEM_PROMPT = ""

  def create
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      # ruby_llm_chat = RubyLLM.chat
      # response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(@message.content)
      Message.create(role: "assistant", content: "Ok", chat: @chat)

      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end

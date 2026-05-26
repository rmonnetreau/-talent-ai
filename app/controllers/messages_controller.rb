class MessagesController < ApplicationController
  # Rails.root.join("app/assets/prompt_recruteur.md").read

  def create # rubocop:disable Metrics/MethodLength
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    system_promt = ChatRole.find(@chat.chat_role_id).prompt_description
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat(model: "gpt-4o")
      response = ruby_llm_chat.with_instructions(system_promt).ask(@message.content)
      Message.create(role: "assistant", content: response.content, chat: @chat)
      redirect_to chat_path(@chat, anchor: "bottom")
    else
      @interview = @chat.interview
      @chat_role = ChatRole.find(@chat.chat_role_id)
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end

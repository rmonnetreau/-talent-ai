class MessagesController < ApplicationController
  # Rails.root.join("app/assets/prompt_recruteur.md").read

  def create # rubocop:disable Metrics/MethodLength
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    system_promt = ChatRole.find(@chat.chat_role_id).prompt_description
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    # if @message.save
    #   # [...]
    #   respond_to do |format|
    #     format.turbo_stream # renders `app/views/messages/create.turbo_stream.erb`
    #     format.html { redirect_to chat_path(@chat) }
    #   end
    # else
    #   respond_to do |format|
    #     format.turbo_stream { render turbo_stream: turbo_stream.update("new_message_container", partial: "messages/form", locals: { chat: @chat, message: @message }) }
    #     format.html { render "chats/show", status: :unprocessable_entity }
    #   end
    # end

    if @message.save
      @ruby_llm_chat = RubyLLM.chat(model: "gpt-4o")
      build_conversation_history
      response = @ruby_llm_chat.with_instructions(system_promt).ask(@message.content)

      @assistant_message = Message.create(role: "assistant", content: response.content, chat: @chat)

      respond_to do |format|
        format.turbo_stream # renders `app/views/messages/create.turbo_stream.erb`
        format.html { redirect_to chat_path(@chat) }
      end
    else
      @interview = @chat.interview
      @chat_role = ChatRole.find(@chat.chat_role_id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("new_message_container", partial: "messages/form",
                                                                            locals: { chat: @chat, message: @message })
        end
        format.html { render "chats/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def build_conversation_history
    @chat.messages.each do |message|
      @ruby_llm_chat.add_message(message)
    end
  end
end

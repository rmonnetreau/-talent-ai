class MessagesController < ApplicationController
  # Rails.root.join("app/assets/prompt_recruteur.md").read

  def create # rubocop:disable Metrics/MethodLength
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    system_prompt = ChatRole.find(@chat.chat_role_id).prompt_description
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      @assistant_message = @chat.messages.create(role: "assistant", content: "", chat: @chat)

      response = ask_llm(system_prompt)

      @assistant_message.update(content: response.content)
      broadcast_replace(@assistant_message)

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

  def ask_llm(system_prompt = nil)
    @ruby_llm_chat = RubyLLM.chat(model: "gpt-4o")
    @ruby_llm_chat = @ruby_llm_chat.with_instructions(system_prompt) if system_prompt.present?

    build_conversation_history

    @ruby_llm_chat.ask(@message.content) do |chunk|
      next if chunk.content.blank? # skip empty chunks

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  end

  def broadcast_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: helpers.dom_id(message),
      partial: "messages/message",
      locals: { message: message, last_assistant: last_assistant }
    )
  end

  def last_assistant
    @chat.messages.where(role: "assistant").order(:created_at).last
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def build_conversation_history
    excluded_ids = [@message&.id, @assistant_message&.id].compact

    @chat.messages
         .where.not(id: excluded_ids)
         .order(:created_at)
         .each do |message|
      @ruby_llm_chat.add_message(message)
    end
  end
end

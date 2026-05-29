class MessagesController < ApplicationController
  # TODO: ElevenLabs TTS – à réactiver avec ELEVENLABS_API_KEY (Azure Speech en alternative gratuite)
  # ELEVENLABS_VOICES = {
  #   "RH"      => "EXAVITQu4vr4xnSDxMaL", # Sarah  – feminine, warm
  #   "Manager" => "VR6AewLTigWG4xSOukaG",  # Arnold – authoritative
  #   "Tech"    => "pNInz6obpgDQGcFmaJgB"   # Adam   – clear
  # }.freeze

  def create # rubocop:disable Metrics/MethodLength
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    profile = current_user.profile
    system_prompt = ChatRole.find(@chat.chat_role_id).prompt_description

    if profile&.cv&.attached?
      system_prompt += <<~PROMPT

        Le candidat a fourni son CV.
        Utilise-le comme contexte pendant tout l'entretien.
      PROMPT
    end

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      @assistant_message = @chat.messages.create(role: "assistant", content: "", chat: @chat)

      broadcast_append(@message)
      broadcast_append(@assistant_message)

      response = ask_llm(system_prompt)

      @assistant_message.update(content: response.content)
      broadcast_replace(@assistant_message)

      respond_to do |format|
        format.turbo_stream
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

  # TODO: ElevenLabs TTS – à réactiver quand ELEVENLABS_API_KEY disponible
  # def audio
  #   chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
  #   message = chat.messages.where(role: "assistant").find(params[:id])
  #   voice_id = elevenlabs_voice_for(chat.chat_role.title)
  #
  #   conn = Faraday.new("https://api.elevenlabs.io") { |f| f.response :raise_error }
  #
  #   tts_response = conn.post("/v1/text-to-speech/#{voice_id}") do |req|
  #     req.headers["xi-api-key"]   = ENV.fetch("ELEVENLABS_API_KEY")
  #     req.headers["Content-Type"] = "application/json"
  #     req.headers["Accept"]       = "audio/mpeg"
  #     req.body = { text: strip_markdown(message.content), model_id: "eleven_multilingual_v2",
  #                  voice_settings: { stability: 0.5, similarity_boost: 0.75 } }.to_json
  #   end
  #
  #   send_data tts_response.body, type: "audio/mpeg", disposition: "inline"
  # end

  private

  def ask_llm(system_prompt = nil)
    @ruby_llm_chat = RubyLLM.chat
    @ruby_llm_chat = @ruby_llm_chat.with_instructions(system_prompt) if system_prompt.present?

    build_conversation_history

    @ruby_llm_chat.ask(@message.content) do |chunk|
      next if chunk.content.blank? # skip empty chunks

      @assistant_message.content += chunk.content
      broadcast_content(@assistant_message)
    end
  end

  def broadcast_append(message)
    Turbo::StreamsChannel.broadcast_append_to(
      @chat,
      target: "messages",
      partial: "messages/message",
      locals: { message: message, last_assistant: nil }
    )
  end

  def broadcast_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: helpers.dom_id(message),
      partial: "messages/message",
      locals: { message: message, last_assistant: last_assistant }
    )
  end

  def broadcast_content(message)
    Turbo::StreamsChannel.broadcast_update_to(
      @chat,
      target: "message_body_#{message.id}",
      partial: "messages/message_body",
      locals: { message: message }
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

  # TODO: ElevenLabs – à réactiver avec l'action audio
  # def elevenlabs_voice_for(role_title)
  #   ELEVENLABS_VOICES.fetch(role_title, ELEVENLABS_VOICES["RH"])
  # end
  #
  # def strip_markdown(text)
  #   text
  #     .gsub(/^\#+ /, "")
  #     .gsub(/\*\*(.+?)\*\*/m, '\1')
  #     .gsub(/\*(.+?)\*/m, '\1')
  #     .gsub(/`(.+?)`/m, '\1')
  #     .gsub(/```.*?```/m, "")
  #     .gsub(/\[(.+?)\]\(.+?\)/, '\1')
  #     .gsub(/^\s*[-*+]\s/, "")
  #     .gsub(/^\s*\d+\.\s/, "")
  #     .strip
  # end
end

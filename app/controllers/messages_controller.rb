class MessagesController < ApplicationController
  # TODO: ElevenLabs TTS – à réactiver avec ELEVENLABS_API_KEY (Azure Speech en alternative gratuite)
  # ELEVENLABS_VOICES = {
  #   "RH"      => "EXAVITQu4vr4xnSDxMaL", # Sarah  – feminine, warm
  #   "Manager" => "VR6AewLTigWG4xSOukaG",  # Arnold – authoritative
  #   "Tech"    => "pNInz6obpgDQGcFmaJgB"   # Adam   – clear
  # }.freeze

  def create # rubocop:disable Metrics/MethodLength
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    system_promt = ChatRole.find(@chat.chat_role_id).prompt_description
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

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

  def message_params
    params.require(:message).permit(:content)
  end

  def build_conversation_history
    @chat.messages.where.not(id: @message.id).each do |message|
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

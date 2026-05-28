class MessagesController < ApplicationController
  def create # rubocop:disable Metrics/MethodLength
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    system_prompt = ChatRole.find(@chat.chat_role_id).prompt_description
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      @assistant_message = @chat.messages.create(role: "assistant", content: "", chat: @chat)

      ask_llm(system_prompt)

      @assistant_message.update(content: @assistant_message.content)

      # Pre-generate TTS before the final broadcast so audio plays instantly on autoplay.
      begin
        mp3 = elevenlabs_tts(strip_markdown(@assistant_message.content))
        Rails.cache.write(tts_cache_key(@assistant_message), mp3, expires_in: 3.hours)
      rescue StandardError => e
        Rails.logger.warn "TTS pre-generation failed: #{e.message}"
      end

      broadcast_replace(@assistant_message, final: true)

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

  def audio
    chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    message = chat.messages.where(role: "assistant").find(params[:id])

    mp3 = Rails.cache.read(tts_cache_key(message)) ||
          elevenlabs_tts(strip_markdown(message.content))
    send_data mp3, type: "audio/mpeg", disposition: "inline"
  end

  private

  def ask_llm(system_prompt = nil)
    @ruby_llm_chat = RubyLLM.chat(model: "gpt-4o")
    @ruby_llm_chat = @ruby_llm_chat.with_instructions(system_prompt) if system_prompt.present?

    build_conversation_history

    @ruby_llm_chat.ask(@message.content) do |chunk|
      next if chunk.content.blank? # skip empty chunks

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message, final: false)
    end
  end

  def broadcast_replace(message, final: true)
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: helpers.dom_id(message),
      partial: "messages/message",
      locals: { message: message, last_assistant: final ? last_assistant : nil }
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

  def elevenlabs_tts(text, voice_id: "kENkNtk0xyzG09WW40xE")
    conn = Faraday.new("https://api.elevenlabs.io")
    response = conn.post("/v1/text-to-speech/#{voice_id}") do |req|
      req.headers["xi-api-key"]   = ENV.fetch("ELEVENLABS_API_KEY")
      req.headers["Content-Type"] = "application/json"
      req.headers["Accept"]       = "audio/mpeg"
      req.body = {
        text: text,
        model_id: "eleven_turbo_v2_5",
        language_code: "fr",
        voice_settings: { stability: 0.5, similarity_boost: 0.75 }
      }.to_json
    end
    raise "ElevenLabs TTS error: #{response.status}" unless response.success?

    response.body
  end

  def tts_cache_key(message)
    "tts_message_#{message.id}"
  end

  def strip_markdown(text)
    text
      .gsub(/```.*?```/m, "")
      .gsub(/^\#{1,6} /, "")
      .gsub(/\*\*(.+?)\*\*/m, '\1')
      .gsub(/\*(.+?)\*/m, '\1')
      .gsub(/`(.+?)`/, '\1')
      .gsub(/\[(.+?)\]\(.+?\)/, '\1')
      .gsub(/^\s*[-*+]\s/, "")
      .gsub(/^\s*\d+\.\s/, "")
      .strip
  end
end

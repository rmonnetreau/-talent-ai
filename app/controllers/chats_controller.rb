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
      Message.create!(
        role: "assistant",
        content: initial_assistant_message,
        chat: @chat
      )

      redirect_to chat_path(@chat, mode: params[:chat_mode])
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

  def initial_assistant_message
    profile = current_user.profile
    chat_role = ChatRole.find(@chat.chat_role_id)
    system_prompt = chat_role.prompt_description
    system_prompt += <<~PROMPT

      Tu dois démarrer un entretien simulé.

      Génère uniquement le premier message du recruteur.

      Le message doit :
      - accueillir le candidat naturellement ;
      - mentionner brièvement le poste ;
      - annoncer une structure simple de l'entretien ;
      - rester court : 3 à 5 phrases maximum ;
      - finir par une première question ouverte.

      Candidat :
      #{profile&.first_name}

      Poste :
      #{@interview.job_title}

      Description du poste :
      #{@interview.job_description}

      Règles strictes :
      - N'utilise jamais de placeholders comme [Prénom], [poste], [élément du CV].
      - Si une information manque, formule naturellement sans l'inventer.
      - Adresse-toi au candidat par son prénom si disponible.
      - Ne mentionne un élément du CV que si tu l'identifies clairement.
    PROMPT
    if profile&.cv&.attached?
      system_prompt += <<~PROMPT

        Le candidat a fourni son CV.
        Utilise-le pour personnaliser légèrement l'accueil, sans faire un résumé complet.
      PROMPT
    end
    ruby_llm_chat = RubyLLM.chat(model: "gpt-4o")
    ruby_llm_chat = ruby_llm_chat.with_instructions(system_prompt)
    if profile&.cv&.attached?
      ruby_llm_chat.ask("Génère le premier message d'accueil de l'entretien.", with: profile.cv).content
    else
      ruby_llm_chat.ask("Génère le premier message d'accueil de l'entretien.").content
    end
  end
end

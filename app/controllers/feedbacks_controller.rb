require "json"

class FeedbacksController < ApplicationController
  SYSTEM_PROMPT = Rails.root.join("app/assets/prompt_coach.md").read
  def create
    @chat = Chat.joins(:interview).where(interviews: { user: current_user }).find(params[:chat_id])
    prompt = <<~PROMPT
      Analyse cette simulation d'entretien.
      job_title:
      #{@chat.interview.job_title}
      job_description:
      #{@chat.interview.job_description}
      chat_role:
      #{@chat.chat_role.title}
      messages:
      #{messages_history}
    PROMPT
    ruby_llm_feedback = RubyLLM.chat(model: "gpt-4o")
    response = ruby_llm_feedback
               .with_instructions(SYSTEM_PROMPT)
               .ask(prompt)

    data = JSON.parse(response.content)

    @feedback = Feedback.create!(
      chat: @chat,
      global_score: data["global_score"],
      strengths: data["strengths"],
      weaknesses: data["weaknesses"],
      best_answer: data["best_answer"],
      worst_answer: data["worst_answer"],
      priority_advice: data["priority_advice"],
      recommended_method: data["recommended_method"]
    )
    @chat.reload
    redirect_to chat_path(@chat), notice: "Feedback généré."
  end

  def messages_history
    @chat.messages.order(:created_at).map do |message|
      "#{message.role}: #{message.content}"
    end.join("\n\n")
  end

  def instructions
    [SYSTEM_PROMPT, messages_history].compact.join("\n\n")
  end
end

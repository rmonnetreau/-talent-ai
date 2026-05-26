class ChatRole < ApplicationRecord
  has_many :chats
  validates :title, presence: true, uniqueness: true
  validates :prompt_description, presence: true

  SHORT_DESCRIPTIONS = {
    "RH" => "Pré-qualification bienveillante : parcours, motivations, fit culturel...",
    "Manager" => "Compétences métier, prise d'initiative, cas concrets, ton challengeant...",
    "Tech" => "Lead technique : cas pratiques, troubleshooting, design problems..."
  }.freeze

  def short_description
    SHORT_DESCRIPTIONS[title]
  end
end

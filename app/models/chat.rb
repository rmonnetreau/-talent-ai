class Chat < ApplicationRecord
  belongs_to :interview
  belongs_to :chat_role
  has_many :messages, dependent: :destroy
  has_one :feedback, dependent: :destroy

  validates :title, presence: true
  validates :chat_role_id, presence: true
end

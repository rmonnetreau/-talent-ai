class Chat < ApplicationRecord
  belongs_to :interview
  belongs_to :chat_role
  has_many :messages, dependent: :destroy
  has_one :feedback, dependent: :destroy
end

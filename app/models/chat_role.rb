class ChatRole < ApplicationRecord
  has_many :chats
  validates :title, presence: true, uniqueness: true
  validates :prompt_description, presence: true
end

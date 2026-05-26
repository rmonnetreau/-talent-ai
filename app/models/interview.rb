class Interview < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  validates :job_title, presence: true
  validates :job_description, presence: true
end

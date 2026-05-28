class Profile < ApplicationRecord
  belongs_to :user

  has_one_attached :cv

  validates :first_name, presence: true
  validates :last_name, presence: true
end

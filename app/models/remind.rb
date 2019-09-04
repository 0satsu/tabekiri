class Remind < ApplicationRecord
  belongs_to :user

  validates :food, length: {maximum: 50},presence: true
  validates :date, presence: true
end

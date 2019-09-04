class User < ApplicationRecord
  has_many :reminds, dependent: :delete_all
  
  validates :last_message, length: {maximun: 100}, allow_nil: true
end

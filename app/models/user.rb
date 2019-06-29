class User < ApplicationRecord
  has_many :reminds, dependent: :delete_all
end

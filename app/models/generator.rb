class Generator < ApplicationRecord
  has_many :generations
  belongs_to :organization
end 
class Organization < ApplicationRecord
  has_many :accounts
  has_many :generators
  has_many :users
end